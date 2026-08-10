const express = require('express');
const auth = require('../middleware/auth');
const Run = require('../models/Run');
const { claimRoute } = require('../territoryService');

const router = express.Router();

/// Normalises whatever the client sent into a GeoJSON LineString (or null).
/// Accepts both the object form `{type, coordinates}` and a bare
/// `[[lng,lat], ...]` array, because app builds have sent both.
function normaliseRoute(route) {
  let coords = null;
  if (Array.isArray(route)) coords = route;
  else if (route && Array.isArray(route.coordinates)) coords = route.coordinates;
  if (!coords) return null;
  const clean = coords
    .filter((c) => Array.isArray(c) && c.length >= 2)
    .map((c) => [Number(c[0]), Number(c[1])])
    .filter((c) => Number.isFinite(c[0]) && Number.isFinite(c[1]));
  if (clean.length < 2) return null;
  return { type: 'LineString', coordinates: clean };
}

// Get user's runs
router.get('/', auth, async (req, res) => {
  try {
    const userId = req.user.id || req.user._id;
    const runs = await Run.find({ userId }).sort({ startedAt: -1 });
    res.json({ success: true, runs });
  } catch (error) {
    console.error('Runs fetch error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Save a new run. Also claims the territory the route covered, so land can
// never be lost to a dropped follow-up request. Re-uploading the same run
// (same clientId) returns the original instead of duplicating it.
router.post('/', auth, async (req, res) => {
  try {
    const userId = req.user.id || req.user._id;
    const runData = req.body || {};
    const route = normaliseRoute(runData.route);
    const clientId = runData.clientId ? String(runData.clientId) : null;

    // Idempotent re-upload: the app retries runs that failed to sync.
    if (clientId) {
      const existing = await Run.findOne({ userId, clientId });
      if (existing) {
        return res.status(200).json({
          success: true,
          run: existing,
          pointsAwarded: 0,
          claimedAreaSqm: existing.claimedAreaSqm || 0,
          duplicate: true,
        });
      }
    }

    // Explicit allow-list rather than spreading the body: a spread let a client
    // set any field on the document, including `_id`, `claimedAreaSqm` and the
    // timestamps. Everything server-authoritative (owner, claimed area, dates)
    // is derived here, never accepted from the caller.
    const startedAt = runData.startedAt ? new Date(runData.startedAt) : new Date();
    const endedAt = runData.endedAt ? new Date(runData.endedAt) : startedAt;
    const num = (v) => {
      const n = Number(v);
      return Number.isFinite(n) && n >= 0 ? n : 0;
    };

    const run = new Run({
      userId,
      clientId: clientId || undefined,
      title: typeof runData.title === 'string' ? runData.title.slice(0, 120) : 'Run',
      startedAt: isNaN(startedAt) ? new Date() : startedAt,
      endedAt: isNaN(endedAt) ? new Date() : endedAt,
      distance: num(runData.distance),
      duration: num(runData.duration),
      pace: num(runData.pace),
      calories: num(runData.calories),
      steps: num(runData.steps),
      route: route || undefined,
    });

    await run.save();

    // Claim the land this run covered. Never fail the save over it — the run
    // itself matters more, and the claim can be retried from the run's route.
    let claimedAreaSqm = 0;
    let territoryMessage = null;
    if (route) {
      try {
        const claim = await claimRoute(userId, route.coordinates);
        claimedAreaSqm = claim.claimed;
        territoryMessage = claim.reason;
        if (claimedAreaSqm > 0) {
          run.claimedAreaSqm = claimedAreaSqm;
          await run.save();
        }
      } catch (e) {
        console.error('Run territory claim error:', e.message);
      }
    }

    // No points are credited here. Rewards are a weekly competition settled when
    // the season closes (see seasonRewards.js): the top holders are paid by how
    // much territory they finished the week with. Paying per run would make
    // holding ground until Monday pointless.
    res.status(201).json({
      success: true,
      run,
      pointsAwarded: 0,
      claimedAreaSqm,
      territoryMessage,
    });
  } catch (error) {
    // A racing duplicate upload trips the unique index — treat it as success.
    if (error && error.code === 11000) {
      const existing = await Run.findOne({
        userId: req.user.id || req.user._id,
        clientId: String((req.body || {}).clientId || ''),
      });
      if (existing) {
        return res.status(200).json({
          success: true,
          run: existing,
          pointsAwarded: 0,
          claimedAreaSqm: existing.claimedAreaSqm || 0,
          duplicate: true,
        });
      }
    }
    console.error('Run save error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Delete one of your own runs. Scoped to the authenticated user, so an id from
// someone else's history simply isn't found.
//
// Territory already claimed is deliberately left alone: it's a union of every
// claim in the season and can't be unpicked one run at a time, and letting a
// delete hand land back to rivals would be an obvious exploit. Deleting a run
// removes it from history only.
router.delete('/:id', auth, async (req, res) => {
  try {
    const userId = req.user.id || req.user._id;
    const result = await Run.deleteOne({ _id: req.params.id, userId });
    if (!result.deletedCount) {
      return res.status(404).json({ success: false, message: 'Run not found' });
    }
    res.json({ success: true });
  } catch (error) {
    console.error('Run delete error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Delete by the client-generated id instead, which is what the app holds for a
// run it recorded locally.
router.delete('/client/:clientId', auth, async (req, res) => {
  try {
    const userId = req.user.id || req.user._id;
    const result = await Run.deleteOne({ clientId: req.params.clientId, userId });
    if (!result.deletedCount) {
      return res.status(404).json({ success: false, message: 'Run not found' });
    }
    res.json({ success: true });
  } catch (error) {
    console.error('Run delete error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

module.exports = router;
