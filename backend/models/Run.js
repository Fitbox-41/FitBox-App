const mongoose = require('mongoose');

const RunSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    required: true,
    ref: 'User'
  },
  startedAt: {
    type: Date,
    required: true
  },
  endedAt: {
    type: Date,
    required: true
  },
  distance: {
    type: Number, // in meters
    required: true
  },
  duration: {
    type: Number, // in seconds
    required: true
  },
  pace: {
    type: Number, // seconds per km
  },
  calories: {
    type: Number
  },
  steps: {
    type: Number
  },
  title: {
    type: String,
    default: 'Run'
  },
  // Client-generated id for the recorded run. Lets a retried upload resolve to
  // the same document instead of creating a duplicate — the app keeps runs
  // locally and re-syncs whatever failed to reach the server.
  clientId: {
    type: String
  },
  // Territory claimed by this run, in square metres (0 if it claimed nothing).
  claimedAreaSqm: {
    type: Number,
    default: 0
  },
  // Optional: indoor/step-only runs have no GPS trace, so a run without a route
  // must still save (it just can't claim territory).
  route: {
    type: {
      type: String,
      enum: ['LineString'],
      default: 'LineString'
    },
    coordinates: {
      type: [[Number]] // Array of arrays of numbers [lng, lat]
    }
  }
}, { timestamps: true });

RunSchema.index({ route: '2dsphere', sparse: true });
RunSchema.index({ userId: 1, startedAt: -1 });
// One document per client-recorded run (per user); sparse so older runs without
// a clientId are unaffected.
RunSchema.index({ userId: 1, clientId: 1 }, { unique: true, sparse: true });

module.exports = mongoose.model('Run', RunSchema, 'runs');
