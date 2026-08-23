const mongoose = require('mongoose');

// What a player claimed during one weekly season.
//
// Territory itself is permanent (see models/Territory.js), so it can't also be
// the basis for the weekly prize — whoever built the biggest holding first
// would win every week forever and a new runner could never place. This tracks
// the week's *new* ground instead, which resets naturally each Monday because a
// new document is created for the new season key.
//
// It also backs the "This week" view on the map, so a player can see what
// they've claimed recently without losing the lifetime picture.
const SeasonProgressSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true,
  },
  // ISO year-week, e.g. "2026-W33".
  season: { type: String, required: true, index: true },
  userName: { type: String, default: 'Runner' },
  // Ground claimed during this season only (GeoJSON Polygon|MultiPolygon).
  geometry: { type: mongoose.Schema.Types.Mixed },
  // Square metres added to the player's holding this season. Counts land taken
  // from rivals as well as empty ground, since both are the week's work.
  areaGainedSqm: { type: Number, default: 0 },
}, { timestamps: true });

SeasonProgressSchema.index({ userId: 1, season: 1 }, { unique: true });
// The weekly leaderboard reads season + rank order.
SeasonProgressSchema.index({ season: 1, areaGainedSqm: -1 });

module.exports = mongoose.model('SeasonProgress', SeasonProgressSchema, 'season_progress');
