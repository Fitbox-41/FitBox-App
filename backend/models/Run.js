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
  route: {
    type: {
      type: String,
      enum: ['LineString'],
      required: true,
      default: 'LineString'
    },
    coordinates: {
      type: [[Number]], // Array of arrays of numbers [lng, lat]
      required: true
    }
  }
}, { timestamps: true });

RunSchema.index({ route: '2dsphere' });
RunSchema.index({ userId: 1, startedAt: -1 });

module.exports = mongoose.model('Run', RunSchema, 'runs');
