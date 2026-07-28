const express = require('express');
const auth = require('../middleware/auth');
const serviceAuth = require('../middleware/serviceAuth');
const Challenge = require('../models/Challenge');
const ChallengeProgress = require('../models/ChallengeProgress');
const Run = require('../models/Run');
const User = require('../models/User');
const WalletTransaction = require('../models/WalletTransaction');

const router = express.Router();

// Progress a user has made toward a challenge from their runs since joining.
// steps → sum of run.steps; distance → sum of run.distance (m) as km.
async function computeProgress(userId, challenge, joinedAt, deadline) {
  const until = new Date(Math.min(Date.now(), new Date(deadline).getTime()));
  const runs = await Run.find({
    userId,
    startedAt: { $gte: new Date(joinedAt), $lte: until },
  }).select('steps distance').lean();
  if (challenge.goalType === 'steps') {
    return runs.reduce((a, r) => a + (Number(r.steps) || 0), 0);
  }
  return runs.reduce((a, r) => a + (Number(r.distance) || 0), 0) / 1000; // km
}

function isLive(c) {
  return c.active && (!c.expiresAt || new Date(c.expiresAt) > new Date());
}

// ---- app-facing ----

// All joinable challenges + this user's status/progress.
router.get('/', auth, async (req, res) => {
  try {
    const userId = req.user.id || req.user._id;
    const challenges = await Challenge.find({ active: true }).sort({ createdAt: -1 }).lean();
    const live = challenges.filter(isLive);
    const progressRows = await ChallengeProgress.find({
      userId,
      challengeId: { $in: live.map((c) => c._id) },
    }).lean();
    const byChallenge = {};
    for (const p of progressRows) byChallenge[String(p.challengeId)] = p;

    const claimedCounts = {};
    await Promise.all(live.map(async (c) => {
      claimedCounts[String(c._id)] =
        await ChallengeProgress.countDocuments({ challengeId: c._id, claimed: true });
    }));

    const out = await Promise.all(live.map(async (c) => {
      const p = byChallenge[String(c._id)];
      let progress = 0;
      let completed = false;
      let canClaim = false;
      const capReached = c.userCap > 0 && claimedCounts[String(c._id)] >= c.userCap;
      if (p) {
        progress = await computeProgress(userId, c, p.joinedAt, p.deadline);
        const withinTime = new Date() <= new Date(p.deadline);
        completed = progress >= c.goalTarget;
        canClaim = completed && withinTime && !p.claimed && !capReached;
      }
      return {
        id: String(c._id),
        title: c.title,
        description: c.description,
        goalType: c.goalType,
        goalTarget: c.goalTarget,
        durationDays: c.durationDays,
        rewardPoints: c.rewardPoints,
        userCap: c.userCap,
        rewardedSoFar: claimedCounts[String(c._id)],
        joined: !!p,
        deadline: p ? p.deadline : null,
        progress,
        completed,
        claimed: p ? p.claimed : false,
        canClaim,
        capReached,
      };
    }));
    res.json({ success: true, challenges: out });
  } catch (error) {
    console.error('Challenges list error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Join a challenge (starts the per-user clock).
router.post('/:id/join', auth, async (req, res) => {
  try {
    const userId = req.user.id || req.user._id;
    const challenge = await Challenge.findById(req.params.id);
    if (!challenge || !isLive(challenge)) {
      return res.status(404).json({ success: false, message: 'Challenge not available' });
    }
    const existing = await ChallengeProgress.findOne({ challengeId: challenge._id, userId });
    if (existing) return res.json({ success: true, alreadyJoined: true });

    const joinedAt = new Date();
    const deadline = new Date(joinedAt.getTime() + challenge.durationDays * 86400000);
    await ChallengeProgress.create({ challengeId: challenge._id, userId, joinedAt, deadline });
    res.status(201).json({ success: true });
  } catch (error) {
    console.error('Challenge join error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Claim the reward once completed (respects the first-N cap).
router.post('/:id/claim', auth, async (req, res) => {
  try {
    const userId = req.user.id || req.user._id;
    const challenge = await Challenge.findById(req.params.id);
    if (!challenge) return res.status(404).json({ success: false, message: 'Not found' });
    const p = await ChallengeProgress.findOne({ challengeId: challenge._id, userId });
    if (!p) return res.status(400).json({ success: false, message: 'Join the challenge first' });
    if (p.claimed) return res.json({ success: true, awarded: 0, alreadyClaimed: true });

    if (new Date() > new Date(p.deadline)) {
      return res.status(400).json({ success: false, message: 'Challenge window has ended' });
    }
    const progress = await computeProgress(userId, challenge, p.joinedAt, p.deadline);
    if (progress < challenge.goalTarget) {
      return res.status(400).json({ success: false, message: 'Goal not reached yet' });
    }
    const claimedCount =
      await ChallengeProgress.countDocuments({ challengeId: challenge._id, claimed: true });
    if (challenge.userCap > 0 && claimedCount >= challenge.userCap) {
      return res.status(409).json({ success: false, message: 'Reward limit reached' });
    }

    // Credit the reward (idempotent per user+challenge).
    const updated = await User.findByIdAndUpdate(
      userId, { $inc: { walletBalance: challenge.rewardPoints } }, { new: true }
    );
    await WalletTransaction.create({
      userId,
      type: 'credit',
      amount: challenge.rewardPoints,
      balanceAfter: updated ? (updated.walletBalance || 0) : challenge.rewardPoints,
      source: 'challenge_reward',
      sourceId: String(challenge._id),
      idempotencyKey: 'challenge_' + challenge._id + '_' + userId,
      description: `Challenge reward: ${challenge.title}`,
    });
    p.claimed = true;
    p.claimedAt = new Date();
    p.rewardRank = claimedCount + 1;
    await p.save();

    res.json({ success: true, awarded: challenge.rewardPoints });
  } catch (error) {
    console.error('Challenge claim error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// ---- admin (service-key gated; used by the admin portal) ----

router.get('/admin/all', serviceAuth, async (req, res) => {
  const challenges = await Challenge.find().sort({ createdAt: -1 }).lean();
  res.json({ success: true, challenges });
});

router.post('/admin', serviceAuth, async (req, res) => {
  try {
    const c = await Challenge.create(req.body);
    res.status(201).json({ success: true, challenge: c });
  } catch (e) {
    res.status(400).json({ success: false, message: e.message });
  }
});

router.put('/admin/:id', serviceAuth, async (req, res) => {
  try {
    const c = await Challenge.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!c) return res.status(404).json({ success: false, message: 'Not found' });
    res.json({ success: true, challenge: c });
  } catch (e) {
    res.status(400).json({ success: false, message: e.message });
  }
});

router.delete('/admin/:id', serviceAuth, async (req, res) => {
  await Challenge.findByIdAndDelete(req.params.id);
  await ChallengeProgress.deleteMany({ challengeId: req.params.id });
  res.json({ success: true });
});

module.exports = router;
