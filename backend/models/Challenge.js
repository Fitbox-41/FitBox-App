const mongoose = require('mongoose');

// A challenge created by an admin. Users join it and have `durationDays` to hit
// the goal (steps or distance) measured from their runs after joining. The
// first `userCap` completers to claim get `rewardPoints` (0 = unlimited).
const ChallengeSchema = new mongoose.Schema({
  title: { type: String, required: true },
  description: { type: String, default: '' },
  goalType: { type: String, enum: ['steps', 'distance'], required: true },
  goalTarget: { type: Number, required: true }, // steps count, or km for distance
  durationDays: { type: Number, required: true, default: 2 },
  rewardPoints: { type: Number, required: true, default: 0 },
  userCap: { type: Number, default: 0 }, // max rewarded completers; 0 = unlimited
  active: { type: Boolean, default: true },
  expiresAt: { type: Date }, // optional: challenge no longer joinable after this
}, { timestamps: true });

module.exports = mongoose.model('Challenge', ChallengeSchema, 'challenges');
