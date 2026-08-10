const express = require('express');
const auth = require('../middleware/auth');
const serviceAuth = require('../middleware/serviceAuth');
const Territory = require('../models/Territory');
const { claimRoute, currentSeason, seasonEndsAt } = require('../territoryService');
const {
  computeSeasonRewards,
  settleSeason,
  isSettled,
  TOP_N,
} = require('../seasonRewards');
const { readPointsConfig } = require('./config');

const router = express.Router();

// The ISO week immediately before the current one — the season that just closed.
function previousSeason(now = new Date()) {
  return currentSeason(new Date(now.getTime() - 7 * 86400000));
}

// Every user's current-season territory — for the shared map (all users see all).
router.get('/', auth, async (req, res) => {
  try {
    const season = currentSeason();

    // Settle the week that just closed, if nobody has yet. Doing it here means
    // rewards land without depending on a scheduler being configured; it costs
    // one extra lookup per request and does real work at most once a week.
    // Never let a settlement problem break the map.
    try {
      const closed = previousSeason();
      if (!(await isSettled(closed))) await settleSeason(closed);
    } catch (e) {
      console.error('Lazy season settle failed:', e.message);
    }

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

// What the current standings would pay if the season ended now. Read-only, so
// the app can show a live "prize" position without settling anything.
router.get('/rewards/preview', auth, async (req, res) => {
  try {
    const season = currentSeason();
    const territories = await Territory.find({ season, area: { $gt: 0 } }).lean();
    const { pointValueInr, seasonTopRewardInr } = await readPointsConfig();
    const rewards = computeSeasonRewards(
      territories.map((t) => ({
        userId: String(t.userId),
        userName: t.userName || 'Runner',
        area: t.area,
      })),
      { pointValueInr, topRewardInr: seasonTopRewardInr },
    );
    const me = String(req.user.id || req.user._id);
    res.json({
      success: true,
      season,
      seasonEndsAt: seasonEndsAt(),
      paidPlaces: TOP_N,
      topRewardInr: seasonTopRewardInr,
      standings: rewards,
      you: rewards.find((r) => r.userId === me) || null,
    });
  } catch (error) {
    console.error('Rewards preview error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Settle a finished season and pay the top holders. Service-key only, and
// idempotent per user per season, so a cron can call it repeatedly.
//
// With no body it settles the season that just closed, and only if it hasn't
// been settled already — that's the safe thing for a scheduled call to hit.
// Pass { season } to settle a specific one.
router.post('/rewards/settle', serviceAuth, async (req, res) => {
  try {
    const explicit = req.body && req.body.season;
    const season = explicit || previousSeason();

    if (season === currentSeason() && !explicit) {
      return res.status(400).json({
        success: false,
        message: 'The current season is still running. Pass { season } to force it.',
      });
    }
    if (!explicit && (await isSettled(season))) {
      return res.json({ success: true, season, alreadySettled: true, paid: 0 });
    }

    const result = await settleSeason(season);
    res.json({ success: true, ...result });
  } catch (error) {
    console.error('Season settle error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

module.exports = router;
