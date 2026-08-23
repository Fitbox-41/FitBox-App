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
  // Territory does NOT reset. It is the lasting record of everywhere a runner
  // has been, and the only thing that reduces it is another player invading —
  // wiping it weekly removed the incentive to capture or defend, and erased the
  // "I've run in all these places" history the map is supposed to tell.
  // Weekly competition progress lives separately, in SeasonProgress.
  //
  // Retained for provenance on documents created while the weekly model was
  // live; no query filters on it any more.
  season: { type: String, index: true },
  userName: { type: String, default: 'Runner' }, // denormalized for map/leaderboard
  geometry: { type: mongoose.Schema.Types.Mixed, required: true }, // GeoJSON Polygon|MultiPolygon
  area: { type: Number, default: 0 }, // square metres currently held
}, { timestamps: true });

// One lifetime territory per user.
TerritorySchema.index({ userId: 1 }, { unique: true });

module.exports = mongoose.model('Territory', TerritorySchema, 'territories');
