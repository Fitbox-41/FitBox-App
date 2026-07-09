const mongoose = require('mongoose');

const TerritorySchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    required: true,
    ref: 'User'
  },
  polygon: {
    type: {
      type: String,
      enum: ['Polygon'],
      required: true,
      default: 'Polygon'
    },
    coordinates: {
      type: [[[Number]]], // Array of arrays of arrays of numbers [[[lng, lat], ...]]
      required: true
    }
  },
  area: {
    type: Number, // Square meters or custom units
    required: true
  },
  weekOf: {
    type: String, // String representation of the week, e.g. "2026-W28"
    required: true
  }
}, { timestamps: true });

TerritorySchema.index({ polygon: '2dsphere' });
TerritorySchema.index({ weekOf: 1 });

module.exports = mongoose.model('Territory', TerritorySchema, 'territories');
