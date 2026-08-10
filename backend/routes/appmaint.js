// One-time maintenance for user segmentation (service-key gated).
//
// Before per-platform sign-in stamping existed, we had no record of whether a
// user signed in on the app or the website. This backfills `lastAppLoginAt` /
// `lastWebLoginAt` from the best available footprint so the admin lists populate
// correctly for existing users; new sign-ins are stamped live from here on.
const express = require('express');
const mongoose = require('mongoose');
const serviceAuth = require('../middleware/serviceAuth');

const router = express.Router();
const coll = (name) => mongoose.connection.db.collection(name);

// GET /api/appmaint/stats — signal counts, to see the data before/after.
router.get('/stats', serviceAuth, async (req, res) => {
  try {
    const [total, withFcm, withAppStamp, withWebStamp, runIds, terrIds, orderIds] =
      await Promise.all([
        coll('users').countDocuments({}),
        coll('users').countDocuments({ fcmTokens: { $exists: true, $ne: [] } }),
        coll('users').countDocuments({ lastAppLoginAt: { $exists: true } }),
        coll('users').countDocuments({ lastWebLoginAt: { $exists: true } }),
        coll('runs').distinct('userId'),
        coll('territories').distinct('userId'),
        coll('orders').distinct('userId'),
      ]);
    res.json({
      success: true,
      total,
      withFcm,
      withAppStamp,
      withWebStamp,
      usersWithRuns: runIds.length,
      usersWithTerritory: terrIds.length,
      usersWithOrders: orderIds.length,
    });
  } catch (e) {
    console.error('appmaint/stats:', e);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// POST /api/appmaint/backfill-segments — set stamps from footprint. Idempotent
// (only fills a stamp that isn't already set). Users with no footprint at all
// default to the website (the users collection is the website's account store).
router.post('/backfill-segments', serviceAuth, async (req, res) => {
  try {
    const [runIds, terrIds, orderIds] = await Promise.all([
      coll('runs').distinct('userId'),
      coll('territories').distinct('userId'),
      coll('orders').distinct('userId'),
    ]);
    const runSet = new Set(runIds.map(String));
    const terrSet = new Set(terrIds.map(String));
    const orderSet = new Set(orderIds.map(String));

    const users = await coll('users')
      .find({}, { projection: { _id: 1, createdAt: 1, fcmTokens: 1, lastAppLoginAt: 1, lastWebLoginAt: 1 } })
      .toArray();

    const ops = [];
    let app = 0;
    let web = 0;
    let defaulted = 0;
    for (const u of users) {
      const id = String(u._id);
      const when = u.createdAt || new Date();
      const hasApp = !!(u.fcmTokens && u.fcmTokens.length) || runSet.has(id) || terrSet.has(id);
      const hasWeb = orderSet.has(id);
      const set = {};
      if (hasApp && !u.lastAppLoginAt) { set.lastAppLoginAt = when; app += 1; }
      if (hasWeb && !u.lastWebLoginAt) { set.lastWebLoginAt = when; web += 1; }
      // No footprint either way → treat as a website account (its native home).
      if (!hasApp && !hasWeb && !u.lastWebLoginAt) { set.lastWebLoginAt = when; defaulted += 1; }
      if (Object.keys(set).length) {
        ops.push({ updateOne: { filter: { _id: u._id }, update: { $set: set } } });
      }
    }
    if (ops.length) await coll('users').bulkWrite(ops, { ordered: false });

    res.json({
      success: true,
      usersScanned: users.length,
      stampedApp: app,
      stampedWeb: web,
      defaultedToWeb: defaulted,
      writes: ops.length,
    });
  } catch (e) {
    console.error('appmaint/backfill-segments:', e);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// POST /api/appmaint/tag — manually mark a user (by email) as an app and/or
// website user. Handy for known testers before they re-sign-in on the new build.
// Body: { email, app?: true, web?: true }
router.post('/tag', serviceAuth, async (req, res) => {
  try {
    const { email, app, web } = req.body || {};
    if (!email) return res.status(400).json({ success: false, message: 'email required' });
    const set = {};
    if (app) set.lastAppLoginAt = new Date();
    if (web) set.lastWebLoginAt = new Date();
    if (!Object.keys(set).length) {
      return res.status(400).json({ success: false, message: 'Set app:true and/or web:true' });
    }
    const r = await coll('users').updateOne({ email }, { $set: set });
    if (!r.matchedCount) return res.status(404).json({ success: false, message: 'No user for that email' });
    res.json({ success: true, email, set });
  } catch (e) {
    console.error('appmaint/tag:', e);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// ---------------------------------------------------------------------------
// Repair tools for the cross-account run leak (fixed in app v1.19.0).
//
// Before that build, run history was cached under one device-wide key, so
// signing in as a second account showed the first account's runs and re-uploaded
// them under the new user — handing over that user's points and territory. The
// signature is the same `clientId` appearing under more than one userId.
// ---------------------------------------------------------------------------

// GET /api/appmaint/leaked-runs — report runs that exist under more than one
// account. Read-only; run this first to see what a fix would touch.
router.get('/leaked-runs', serviceAuth, async (req, res) => {
  try {
    const groups = await coll('runs').aggregate([
      { $match: { clientId: { $exists: true, $ne: null } } },
      {
        $group: {
          _id: '$clientId',
          users: { $addToSet: '$userId' },
          runs: { $push: { _id: '$_id', userId: '$userId', createdAt: '$createdAt', distance: '$distance' } },
        },
      },
      { $match: { 'users.1': { $exists: true } } }, // 2+ distinct owners
    ]).toArray();

    res.json({
      success: true,
      duplicatedClientIds: groups.length,
      extraRuns: groups.reduce((n, g) => n + (g.runs.length - 1), 0),
      groups: groups.map((g) => ({
        clientId: g._id,
        owners: g.users.map(String),
        runs: g.runs
          .map((r) => ({ id: String(r._id), userId: String(r.userId), createdAt: r.createdAt, distance: r.distance }))
          .sort((a, b) => new Date(a.createdAt) - new Date(b.createdAt)),
      })),
    });
  } catch (e) {
    console.error('appmaint/leaked-runs:', e);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// POST /api/appmaint/fix-leaked-runs — keep the earliest upload of each
// duplicated run and delete the copies, reversing the points they were awarded.
// Body: { confirm: true }. Territory is NOT corrected here — run
// /rebuild-territory afterwards.
router.post('/fix-leaked-runs', serviceAuth, async (req, res) => {
  try {
    if (!req.body || req.body.confirm !== true) {
      return res.status(400).json({ success: false, message: 'Send { "confirm": true } — this deletes runs and reverses points.' });
    }

    const groups = await coll('runs').aggregate([
      { $match: { clientId: { $exists: true, $ne: null } } },
      { $group: { _id: '$clientId', users: { $addToSet: '$userId' }, runs: { $push: { _id: '$_id', userId: '$userId', createdAt: '$createdAt' } } } },
      { $match: { 'users.1': { $exists: true } } },
    ]).toArray();

    let deleted = 0;
    let pointsReversed = 0;
    const affectedUsers = new Set();

    for (const g of groups) {
      // The original is whichever copy was uploaded first.
      const ordered = g.runs.slice().sort((a, b) => new Date(a.createdAt) - new Date(b.createdAt));
      const duplicates = ordered.slice(1);

      for (const dup of duplicates) {
        const runId = String(dup._id);
        affectedUsers.add(String(dup.userId));

        // Reverse the reward this copy paid out, if any.
        const ledger = await coll('wallet_transactions').findOne({ idempotencyKey: 'run_' + runId });
        if (ledger && ledger.amount > 0) {
          await coll('users').updateOne(
            { _id: dup.userId },
            { $inc: { walletBalance: -ledger.amount } }
          );
          await coll('wallet_transactions').deleteOne({ _id: ledger._id });
          pointsReversed += ledger.amount;
        }

        await coll('runs').deleteOne({ _id: dup._id });
        deleted += 1;
      }
    }

    res.json({
      success: true,
      duplicatedClientIds: groups.length,
      runsDeleted: deleted,
      pointsReversed,
      affectedUsers: [...affectedUsers],
      next: 'POST /api/appmaint/rebuild-territory to recompute the map from the surviving runs.',
    });
  } catch (e) {
    console.error('appmaint/fix-leaked-runs:', e);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// POST /api/appmaint/rebuild-territory — recompute the current season's map from
// scratch by replaying every run of the season in chronological order. Territory
// is a union, so a wrongly-attributed claim can't be subtracted out again; this
// is the way back to a correct map. Body: { confirm: true, season?: "2026-W32" }.
router.post('/rebuild-territory', serviceAuth, async (req, res) => {
  try {
    if (!req.body || req.body.confirm !== true) {
      return res.status(400).json({ success: false, message: 'Send { "confirm": true } — this rewrites the season map.' });
    }
    const { claimRoute, currentSeason } = require('../territoryService');
    const season = (req.body && req.body.season) || currentSeason();

    // Season bounds: the ISO week that `season` names, Monday 00:00 UTC to the
    // following Monday.
    const now = new Date();
    const monday = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
    monday.setUTCDate(monday.getUTCDate() - ((monday.getUTCDay() + 6) % 7));
    const nextMonday = new Date(monday.getTime() + 7 * 86400000);

    await coll('territories').deleteMany({ season });

    const runs = await coll('runs')
      .find({
        startedAt: { $gte: monday, $lt: nextMonday },
        'route.coordinates.1': { $exists: true },
      })
      .sort({ startedAt: 1 })
      .toArray();

    let replayed = 0;
    let skipped = 0;
    for (const run of runs) {
      try {
        const result = await claimRoute(run.userId, run.route.coordinates);
        if (result.ok) replayed += 1;
        else skipped += 1;
      } catch (e) {
        skipped += 1;
      }
    }

    const totals = await coll('territories').find({ season }).toArray();
    res.json({
      success: true,
      season,
      runsConsidered: runs.length,
      replayed,
      skipped,
      holdings: totals.map((t) => ({ userId: String(t.userId), userName: t.userName, areaSqm: Math.round(t.area || 0) })),
    });
  } catch (e) {
    console.error('appmaint/rebuild-territory:', e);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

module.exports = router;
