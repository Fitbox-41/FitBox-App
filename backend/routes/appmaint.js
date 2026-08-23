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

// POST /api/appmaint/merge-territory-lifetime — one-off migration for the move
// from weekly territory to permanent territory.
//
// Under the old model each user got a fresh document per ISO week, so a player
// who ran across three weeks has three documents and the map only ever showed
// the newest. This unions them into a single lifetime holding per user and
// deletes the rest. Body: { confirm: true }.
//
// Safe to re-run: after the first pass each user has exactly one document, and
// unioning one geometry with nothing is a no-op.
router.post('/merge-territory-lifetime', serviceAuth, async (req, res) => {
  try {
    if (!req.body || req.body.confirm !== true) {
      return res.status(400).json({ success: false, message: 'Send { "confirm": true } — this rewrites territory documents.' });
    }
    const { mergeGeometry, areaOf } = require('../territoryEngine');
    const turf = require('@turf/turf');

    const grouped = await coll('territories').aggregate([
      { $group: { _id: '$userId', docs: { $push: { _id: '$_id', geometry: '$geometry', area: '$area', userName: '$userName', season: '$season' } } } },
    ]).toArray();

    let usersProcessed = 0;
    let docsRemoved = 0;
    const holdings = [];

    for (const g of grouped) {
      const docs = g.docs.filter((d) => d.geometry);
      if (!docs.length) continue;

      // Union every season this user ever held.
      let geometry = docs[0].geometry;
      for (let i = 1; i < docs.length; i++) {
        geometry = mergeGeometry(geometry, turf.feature(docs[i].geometry));
      }
      const area = areaOf(geometry);
      const userName = (docs.find((d) => d.userName && d.userName !== 'Runner') || docs[0]).userName || 'Runner';

      // Keep the oldest document as the survivor so createdAt stays meaningful.
      const ordered = g.docs.slice().sort((a, b) => String(a._id).localeCompare(String(b._id)));
      const keep = ordered[0]._id;

      await coll('territories').updateOne(
        { _id: keep },
        { $set: { geometry, area, userName } },
      );
      const del = await coll('territories').deleteMany({ userId: g._id, _id: { $ne: keep } });
      docsRemoved += del.deletedCount || 0;
      usersProcessed += 1;
      holdings.push({ userId: String(g._id), userName, areaSqm: Math.round(area), merged: docs.length });
    }

    res.json({ success: true, usersProcessed, docsRemoved, holdings });
  } catch (e) {
    console.error('appmaint/merge-territory-lifetime:', e);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// POST /api/appmaint/rebuild-territory — recompute the whole map from scratch by
// replaying every recorded run in chronological order. Territory is a union, so
// a wrongly-attributed claim can't be subtracted out again; replaying is the way
// back to a correct map. Body: { confirm: true, since?: "2026-08-01" }.
//
// Rebuilds the LIFETIME map (territory no longer resets weekly), and the weekly
// progress rows are rebuilt with it because claimRoute writes both.
router.post('/rebuild-territory', serviceAuth, async (req, res) => {
  try {
    if (!req.body || req.body.confirm !== true) {
      return res.status(400).json({ success: false, message: 'Send { "confirm": true } — this rewrites the map.' });
    }
    const { claimRoute } = require('../territoryService');

    // Optional lower bound, for replaying only recent history on a large data set.
    const since = req.body.since ? new Date(req.body.since) : null;
    const match = { 'route.coordinates.1': { $exists: true } };
    if (since && !isNaN(since)) match.startedAt = { $gte: since };

    await coll('territories').deleteMany({});
    await coll('season_progress').deleteMany({});

    const runs = await coll('runs').find(match).sort({ startedAt: 1 }).toArray();

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

    const totals = await coll('territories').find({}).toArray();
    res.json({
      success: true,
      scope: since ? `runs since ${since.toISOString()}` : 'all runs',
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

// GET /api/appmaint/duplicate-tokens — devices attached to more than one
// account. Read-only. A push token identifies a phone, so a token on two users
// means one of them receives the other's notifications.
router.get('/duplicate-tokens', serviceAuth, async (req, res) => {
  try {
    const groups = await coll('users').aggregate([
      { $match: { fcmTokens: { $exists: true, $ne: [] } } },
      { $unwind: '$fcmTokens' },
      { $group: { _id: '$fcmTokens', users: { $addToSet: { _id: '$_id', email: '$email' } } } },
      { $match: { 'users.1': { $exists: true } } },
    ]).toArray();

    res.json({
      success: true,
      duplicatedTokens: groups.length,
      groups: groups.map((g) => ({
        token: String(g._id).slice(0, 12) + '…', // never echo a full token
        holders: g.users.map((u) => ({ userId: String(u._id), email: u.email })),
      })),
    });
  } catch (e) {
    console.error('appmaint/duplicate-tokens:', e);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// POST /api/appmaint/fix-duplicate-tokens — leave each shared token on the most
// recently active account only. Body: { confirm: true }.
//
// New sign-ins repair themselves (POST /push/register now pulls the token off
// its previous owner), but devices poisoned before that shipped stay wrong
// until they sign in again — this cleans them immediately.
router.post('/fix-duplicate-tokens', serviceAuth, async (req, res) => {
  try {
    if (!req.body || req.body.confirm !== true) {
      return res.status(400).json({ success: false, message: 'Send { "confirm": true }.' });
    }

    const groups = await coll('users').aggregate([
      { $match: { fcmTokens: { $exists: true, $ne: [] } } },
      { $unwind: '$fcmTokens' },
      { $group: { _id: '$fcmTokens', users: { $addToSet: { _id: '$_id', seen: '$lastAppLoginAt' } } } },
      { $match: { 'users.1': { $exists: true } } },
    ]).toArray();

    let tokensFixed = 0;
    let detached = 0;
    for (const g of groups) {
      // Keep the token with whoever used the app most recently; that is the
      // account actually signed in on the handset.
      const ordered = g.users.slice().sort(
        (a, b) => new Date(b.seen || 0) - new Date(a.seen || 0),
      );
      const keep = ordered[0]._id;
      const r = await coll('users').updateMany(
        { _id: { $ne: keep }, fcmTokens: g._id },
        { $pull: { fcmTokens: g._id } },
      );
      tokensFixed += 1;
      detached += r.modifiedCount || 0;
    }

    res.json({ success: true, tokensFixed, accountsDetached: detached });
  } catch (e) {
    console.error('appmaint/fix-duplicate-tokens:', e);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// ---------------------------------------------------------------------------
// Point expiry (99 days, FIFO). No scheduler exists in this project, so the
// sweep runs lazily per user on a wallet read; these are the bulk equivalents.
// ---------------------------------------------------------------------------

// POST /api/appmaint/backfill-expiry — give credits issued before expiry
// existed a `remaining` and an `expiresAt`. Safe to re-run; only fills gaps.
router.post('/backfill-expiry', serviceAuth, async (req, res) => {
  try {
    const { backfill, EXPIRY_DAYS } = require('../pointsExpiry');
    const updated = await backfill();
    res.json({ success: true, creditsBackfilled: updated, expiryDays: EXPIRY_DAYS });
  } catch (e) {
    console.error('appmaint/backfill-expiry:', e);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// GET /api/appmaint/expiry-status — what is live, what is already overdue.
// Read-only; run before sweeping so the effect is known in advance.
router.get('/expiry-status', serviceAuth, async (req, res) => {
  try {
    const now = new Date();
    const soon = new Date(now.getTime() + 14 * 86400000);
    const agg = await coll('wallet_transactions').aggregate([
      { $match: { type: 'credit', remaining: { $gt: 0 } } },
      {
        $group: {
          _id: null,
          liveCredits: { $sum: 1 },
          livePoints: { $sum: '$remaining' },
          overduePoints: {
            $sum: { $cond: [{ $lte: ['$expiresAt', now] }, '$remaining', 0] },
          },
          expiringIn14Days: {
            $sum: {
              $cond: [
                { $and: [{ $gt: ['$expiresAt', now] }, { $lte: ['$expiresAt', soon] }] },
                '$remaining',
                0,
              ],
            },
          },
          missingExpiry: {
            $sum: { $cond: [{ $eq: [{ $type: '$expiresAt' }, 'missing'] }, 1, 0] },
          },
        },
      },
    ]).toArray();
    res.json({ success: true, ...(agg[0] || {}), _id: undefined });
  } catch (e) {
    console.error('appmaint/expiry-status:', e);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// POST /api/appmaint/expire-points — sweep every user with overdue points.
// Body: { confirm: true }. Each expiry is a real ledger row, so the drop is
// explainable to the customer afterwards.
router.post('/expire-points', serviceAuth, async (req, res) => {
  try {
    if (!req.body || req.body.confirm !== true) {
      return res.status(400).json({ success: false, message: 'Send { "confirm": true } — this removes points.' });
    }
    const { expireUserPoints } = require('../pointsExpiry');
    const userIds = await coll('wallet_transactions').distinct('userId', {
      type: 'credit',
      remaining: { $gt: 0 },
      expiresAt: { $lte: new Date() },
    });

    let usersAffected = 0;
    let pointsExpired = 0;
    for (const id of userIds) {
      const n = await expireUserPoints(id);
      if (n > 0) { usersAffected += 1; pointsExpired += n; }
    }
    res.json({ success: true, usersScanned: userIds.length, usersAffected, pointsExpired });
  } catch (e) {
    console.error('appmaint/expire-points:', e);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// POST /api/appmaint/backfill-season-progress — recreate this week's leaderboard
// rows from runs already recorded.
//
// `season_progress` is only written by claimRoute, which means any run saved
// *before* weekly tracking shipped left no row. On the map that shows up as
// "This week: 0 m²" next to a lifetime holding the player clearly earned during
// that same week, and — worse — the Monday settlement would rank nobody and pay
// nobody, exactly the way the 10 August rollover did.
//
// Recomputes from the run routes themselves rather than trusting the stored
// `claimedAreaSqm`, so the geometry backing the "This week" map view is real.
router.post('/backfill-season-progress', serviceAuth, async (req, res) => {
  try {
    const { currentSeason } = require('../territoryService');
    const { routeToClaim, areaOf, mergeGeometry } = require('../territoryEngine');
    const season = req.body && req.body.season ? String(req.body.season) : currentSeason();

    // The ISO week this season key refers to, so we pick up exactly its runs.
    const [yearStr, weekStr] = season.split('-W');
    const jan4 = new Date(Date.UTC(Number(yearStr), 0, 4));
    const weekStart = new Date(jan4);
    weekStart.setUTCDate(jan4.getUTCDate() - ((jan4.getUTCDay() + 6) % 7) + (Number(weekStr) - 1) * 7);
    const weekEnd = new Date(weekStart.getTime() + 7 * 86400000);

    const runs = await coll('runs')
      .find({ startedAt: { $gte: weekStart, $lt: weekEnd }, route: { $ne: null } })
      .sort({ startedAt: 1 })
      .toArray();

    const byUser = new Map();
    for (const r of runs) {
      if (!r.route || !r.route.coordinates) continue;
      const claim = routeToClaim(r.route.coordinates);
      if (!claim) continue;
      const cur = byUser.get(String(r.userId)) || { userId: r.userId, geometry: null };
      cur.geometry = mergeGeometry(cur.geometry, claim);
      byUser.set(String(r.userId), cur);
    }

    const applied = [];
    for (const entry of byUser.values()) {
      const area = areaOf(entry.geometry);
      const user = await coll('users').findOne({ _id: entry.userId });
      const existing = await coll('season_progress').findOne({ userId: entry.userId, season });
      if (existing && existing.areaGainedSqm >= area) {
        applied.push({ user: user && user.email, skipped: 'already ahead' });
        continue;
      }
      await coll('season_progress').updateOne(
        { userId: entry.userId, season },
        {
          $set: {
            userName: (user && user.name) || 'Runner',
            geometry: entry.geometry,
            areaGainedSqm: area,
            updatedAt: new Date(),
          },
          $setOnInsert: { createdAt: new Date() },
        },
        { upsert: true },
      );
      applied.push({ user: user && user.email, areaGainedSqm: Math.round(area) });
    }

    res.json({
      success: true,
      season,
      window: { from: weekStart.toISOString(), to: weekEnd.toISOString() },
      runsConsidered: runs.length,
      applied,
    });
  } catch (error) {
    console.error('backfill-season-progress error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
});

module.exports = router;
