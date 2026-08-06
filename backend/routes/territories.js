const express = require('express');
const auth = require('../middleware/auth');
const Territory = require('../models/Territory');
const { claimRoute, currentSeason, seasonEndsAt } = require('../territoryService');

const router = express.Router();

// Every user's current-season territory — for the shared map (all users see all).
router.get('/', auth, async (req, res) => {
  try {
    const season = currentSeason();
    const territories =
      await Territory.find({ season, area: { $gt: 0 } }).lean();
    res.json({
      success: true,
      season,
      seasonEndsAt: seasonEndsAt(),
      territories: territories.map((t) => ({
        userId: String(t.userId),
        userName: t.userName || 'Runner',
        geometry: t.geometry,
        area: t.area,
      })),
    });
  } catch (error) {
    console.error('Territories fetch error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Capture territory from a completed run.
// Body: { route: [[lng, lat], ...] } (GeoJSON order). The run claims a corridor
// along its route plus any area it encloses; overlap with OTHER users'
// territory is subtracted from them and unioned into the caller's.
//
// Saving a run (POST /api/runs) now claims territory on its own, so this
// endpoint is only needed by older app builds and for re-claiming a past run.
router.post('/capture', auth, async (req, res) => {
  try {
    const userId = req.user.id || req.user._id;
    const result = await claimRoute(userId, req.body && req.body.route);
    if (!result.ok) {
      return res.status(400).json({ success: false, message: result.reason });
    }
    res.json({
      success: true,
      area: result.total, // caller's new total
      claimed: result.claimed, // area this run covered
    });
  } catch (error) {
    console.error('Territory capture error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

module.exports = router;
