const express = require('express');
const auth = require('../middleware/auth');
const Run = require('../models/Run');
const User = require('../models/User');
const WalletTransaction = require('../models/WalletTransaction');

const router = express.Router();

// Activity reward: 10 points per km (1 point = ₹0.10, so ₹1/km). Tunable.
const POINTS_PER_KM = 10;

// Get user's runs
router.get('/', auth, async (req, res) => {
  try {
    const userId = req.user.id || req.user._id;
    const runs = await Run.find({ userId }).sort({ startedAt: -1 });
    res.json({ success: true, runs });
  } catch (error) {
    console.error('Runs fetch error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Save a new run
router.post('/', auth, async (req, res) => {
  try {
    const userId = req.user.id || req.user._id;
    const runData = req.body;

    // Spread first, then set userId, so a client cannot override the
    // authenticated user by passing userId in the request body.
    const run = new Run({
      ...runData,
      userId
    });

    await run.save();

    // Reward wallet points for the distance covered. Server-authoritative +
    // idempotent per run so a retry can't double-credit.
    let pointsAwarded = 0;
    try {
      const km = (Number(run.distance) || 0) / 1000;
      pointsAwarded = Math.round(km * POINTS_PER_KM);
      if (pointsAwarded > 0) {
        const updated = await User.findByIdAndUpdate(
          userId,
          { $inc: { walletBalance: pointsAwarded } },
          { new: true }
        );
        await WalletTransaction.create({
          userId,
          type: 'credit',
          amount: pointsAwarded,
          balanceAfter: updated ? (updated.walletBalance || 0) : pointsAwarded,
          source: 'run_reward',
          sourceId: run._id.toString(),
          idempotencyKey: 'run_' + run._id.toString(),
          description: `Reward for a ${km.toFixed(2)} km run`
        });
      }
    } catch (e) {
      console.error('Run reward error:', e.message);
      pointsAwarded = 0; // never fail the run save over a reward hiccup
    }

    res.status(201).json({ success: true, run, pointsAwarded });
  } catch (error) {
    console.error('Run save error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

module.exports = router;
