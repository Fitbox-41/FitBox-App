const mongoose = require('mongoose');

// One row per (user, challenge) they've joined. Progress is computed on demand
// from the user's runs; this row records the join window + claim state.
const ChallengeProgressSchema = new mongoose.Schema({
  challengeId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Challenge',
    required: true,
    index: true,
  },
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true,
  },
  joinedAt: { type: Date, required: true },
  deadline: { type: Date, required: true },
  claimed: { type: Boolean, default: false },
  claimedAt: { type: Date },
  rewardRank: { type: Number }, // completer rank at claim time (for the cap)
}, { timestamps: true });

ChallengeProgressSchema.index({ challengeId: 1, userId: 1 }, { unique: true });

module.exports =
  mongoose.model('ChallengeProgress', ChallengeProgressSchema, 'challenge_progress');
