const mongoose = require('mongoose');

// One territory document per user — the union of everything they currently hold
// (a GeoJSON Polygon or MultiPolygon, since contests fragment territory). Stored
// as Mixed because the geometry alternates between Polygon and MultiPolygon; the
// shared map just reads all docs, so no geo-index/query is needed.
const TerritorySchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    unique: true,
    index: true,
  },
  userName: { type: String, default: 'Runner' }, // denormalized for map/leaderboard
  geometry: { type: mongoose.Schema.Types.Mixed, required: true }, // GeoJSON Polygon|MultiPolygon
  area: { type: Number, default: 0 }, // square metres currently held
}, { timestamps: true });

module.exports = mongoose.model('Territory', TerritorySchema, 'territories');
