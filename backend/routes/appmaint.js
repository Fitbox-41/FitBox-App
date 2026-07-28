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

module.exports = router;
