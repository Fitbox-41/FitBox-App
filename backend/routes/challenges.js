const express = require('express');
const auth = require('../middleware/auth');
const serviceAuth = require('../middleware/serviceAuth');
const Challenge = require('../models/Challenge');
const ChallengeProgress = require('../models/ChallengeProgress');
const Run = require('../models/Run');
const User = require('../models/User');
const WalletTransaction = require('../models/WalletTransaction');
const { notifyAllAppUsers } = require('../fcm');
const { creditExpiry } = require('../pointsExpiry');

const router = express.Router();

// Progress a user has made toward a challenge, summed from a list of runs
// already loaded. steps → sum of run.steps; distance → sum of run.distance (m)
// as km.
//
// This takes the runs rather than fetching them because the listing below needs
// the same runs for every challenge the user has joined — see the note there.
function progressFrom(runs, challenge, joinedAt, deadline) {
  const from = new Date(joinedAt).getTime();
  const until = Math.min(Date.now(), new Date(deadline).getTime());
  const window = runs.filter((r) => {
    const t = new Date(r.startedAt).getTime();
    return t >= from && t <= until;
  });
  if (challenge.goalType === 'steps') {
    return window.reduce((a, r) => a + (Number(r.steps) || 0), 0);
  }
  return window.reduce((a, r) => a + (Number(r.distance) || 0), 0) / 1000; // km
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

    // One aggregation instead of a countDocuments per challenge. This endpoint
    // used to issue 2N+2 queries for N challenges — a round trip to Atlas each,
    // which is what made the Challenges tab feel slow to open. It is now three,
    // and stays three however many challenges exist.
    const claimedCounts = {};
    const counts = await ChallengeProgress.aggregate([
      { $match: { challengeId: { $in: live.map((c) => c._id) }, claimed: true } },
      { $group: { _id: '$challengeId', n: { $sum: 1 } } },
    ]);
    for (const row of counts) claimedCounts[String(row._id)] = row.n;

    // Likewise the user's runs, fetched once for the earliest window any joined
    // challenge needs and then filtered per challenge in memory. The windows
    // overlap heavily — they all end now — so re-querying per challenge was
    // fetching the same rows several times over.
    const joined = live.map((c) => byChallenge[String(c._id)]).filter(Boolean);
    let runs = [];
    if (joined.length) {
      const earliest = new Date(
        Math.min(...joined.map((p) => new Date(p.joinedAt).getTime())),
      );
      runs = await Run.find({ userId, startedAt: { $gte: earliest } })
        .select('steps distance startedAt')
        .lean();
    }

    const out = live.map((c) => {
      const p = byChallenge[String(c._id)];
      let progress = 0;
      let completed = false;
      let canClaim = false;
      const capReached = c.userCap > 0 && (claimedCounts[String(c._id)] || 0) >= c.userCap;
      if (p) {
        progress = progressFrom(runs, c, p.joinedAt, p.deadline);
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
        rewardedSoFar: claimedCounts[String(c._id)] || 0,
        joined: !!p,
        deadline: p ? p.deadline : null,
        progress,
        completed,
        claimed: p ? p.claimed : false,
        canClaim,
        capReached,
      };
    });
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
    const runs = await Run.find({ userId, startedAt: { $gte: new Date(p.joinedAt) } })
      .select('steps distance startedAt')
      .lean();
    const progress = progressFrom(runs, challenge, p.joinedAt, p.deadline);
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
      remaining: challenge.rewardPoints,
      expiresAt: creditExpiry(),
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

    // Announce it, so a new challenge actually reaches people instead of only
    // appearing to whoever happens to open the Challenges screen. Awaited
    // rather than fired and forgotten: on serverless the function can be frozen
    // the moment the response is sent, which would drop the send.
    let announced = { recipients: 0, sent: 0 };
    if (c.active) {
      const goal =
        c.goalType === 'distance'
          ? `${c.goalTarget} km`
          : `${Number(c.goalTarget).toLocaleString()} steps`;
      announced = await notifyAllAppUsers({
        title: 'New challenge: ' + c.title,
        body:
          `${goal} in ${c.durationDays} day${c.durationDays === 1 ? '' : 's'}` +
          (c.rewardPoints > 0 ? ` · ${c.rewardPoints} points` : '') +
          '. Tap to join.',
        data: { type: 'challenge', challengeId: String(c._id) },
      });
    }

    res.status(201).json({ success: true, challenge: c, announced });
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
