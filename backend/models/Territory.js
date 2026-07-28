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
    index: true,
  },
  // Weekly season (ISO year-week, e.g. "2026-W31"). Territory resets each week:
  // the map/leaderboard only count the current season, so past weeks drop off.
  season: { type: String, required: true, index: true },
  userName: { type: String, default: 'Runner' }, // denormalized for map/leaderboard
  geometry: { type: mongoose.Schema.Types.Mixed, required: true }, // GeoJSON Polygon|MultiPolygon
  area: { type: Number, default: 0 }, // square metres currently held
}, { timestamps: true });

// One territory per user per season.
TerritorySchema.index({ userId: 1, season: 1 }, { unique: true });

module.exports = mongoose.model('Territory', TerritorySchema, 'territories');
