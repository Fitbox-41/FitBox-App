const express = require('express');
const auth = require('../middleware/auth');
const serviceAuth = require('../middleware/serviceAuth');
const Territory = require('../models/Territory');
const SeasonProgress = require('../models/SeasonProgress');
const Run = require('../models/Run');
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

    // Two views of the same map:
    //   lifetime (default) — everywhere the player still holds, never reset
    //   week               — only what was claimed during the current season
    const view = req.query.view === 'week' ? 'week' : 'lifetime';

    const holdings = view === 'week'
      ? await SeasonProgress.find({ season, areaGainedSqm: { $gt: 0 } }).lean()
      : await Territory.find({ area: { $gt: 0 } }).lean();

    // Per-owner run totals, so a territory can show who holds it and what they
    // did to earn it. One aggregation for everyone on the map rather than a
    // query per territory.
    const ownerIds = holdings.map((t) => t.userId);
    const stats = await Run.aggregate([
      { $match: { userId: { $in: ownerIds } } },
      {
        $group: {
          _id: '$userId',
          distanceKm: { $sum: { $divide: [{ $ifNull: ['$distance', 0] }, 1000] } },
          steps: { $sum: { $ifNull: ['$steps', 0] } },
          runs: { $sum: 1 },
        },
      },
    ]);
    const byUser = new Map(stats.map((s) => [String(s._id), s]));

    // Ranked here rather than in the app so every client agrees on the order.
    const sorted = holdings
      .map((t) => ({ t, area: view === 'week' ? t.areaGainedSqm : t.area }))
      .sort((a, b) => b.area - a.area);

    res.json({
      success: true,
      season,
      seasonEndsAt: seasonEndsAt(),
      view,
      territories: sorted.map(({ t, area }, i) => {
        const s = byUser.get(String(t.userId));
        return {
          userId: String(t.userId),
          userName: t.userName || 'Runner',
          photoUrl: t.photoUrl || null,
          geometry: t.geometry,
          area,
          rank: i + 1,
          distanceKm: s ? Math.round(s.distanceKm * 10) / 10 : 0,
          steps: s ? s.steps : 0,
          runs: s ? s.runs : 0,
        };
      }),
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
    // The weekly prize ranks ground gained this week, not the lifetime holding —
    // otherwise the biggest landowner wins every week and nobody can catch up.
    const territories = (await SeasonProgress.find({ season, areaGainedSqm: { $gt: 0 } }).lean())
      .map((p) => ({ ...p, area: p.areaGainedSqm }));
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
