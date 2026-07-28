const express = require('express');
const auth = require('../middleware/auth');
const Territory = require('../models/Territory');
const User = require('../models/User');
const { routeToPolygon, applyCapture, areaOf } = require('../territoryEngine');
const { notifyUser } = require('../fcm');

const router = express.Router();

// ISO year-week, e.g. "2026-W31" — the current weekly territory season.
function currentSeason(now = new Date()) {
  const date = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
  const dayNum = (date.getUTCDay() + 6) % 7; // Mon=0..Sun=6
  date.setUTCDate(date.getUTCDate() - dayNum + 3); // nearest Thursday
  const firstThursday = date.getTime();
  date.setUTCMonth(0, 1);
  if (date.getUTCDay() !== 4) {
    date.setUTCMonth(0, 1 + ((4 - date.getUTCDay()) + 7) % 7);
  }
  const week = 1 + Math.ceil((firstThursday - date.getTime()) / 604800000);
  const year = new Date(firstThursday).getUTCFullYear();
  return `${year}-W${String(week).padStart(2, '0')}`;
}

// Next Monday 00:00 UTC — when the current season resets.
function seasonEndsAt(now = new Date()) {
  const d = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
  const daysToMon = ((8 - d.getUTCDay()) % 7) || 7; // next Monday
  d.setUTCDate(d.getUTCDate() + daysToMon);
  return d.toISOString();
}

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

// Capture territory from a completed run loop.
// Body: { route: [[lng, lat], ...] } (GeoJSON order). The route is closed into a
// polygon; any overlap with OTHER users' territory is subtracted from them
// (transferred to the capturer), and the polygon is unioned into the capturer's.
router.post('/capture', auth, async (req, res) => {
  try {
    const userId = req.user.id || req.user._id;
    const newPoly = routeToPolygon(req.body && req.body.route);
    if (!newPoly) {
      return res.status(400).json({
        success: false,
        message: 'Run a full loop to claim territory.',
      });
    }

    // Only the current season is in play — past weeks are archived history, so
    // everyone effectively starts fresh each Monday.
    const season = currentSeason();
    const mine = await Territory.findOne({ userId, season });
    const others = await Territory.find({ userId: { $ne: userId }, season });

    const result = applyCapture(
      mine ? mine.geometry : null,
      others.map((o) => ({ id: o._id, geometry: o.geometry })),
      newPoly,
    );

    // Who we're taking from (for the "under attack" push).
    const othersById = new Map(others.map((o) => [String(o._id), o]));

    // Apply contests to other users (shrink or remove).
    for (const u of result.updatedOthers) {
      if (!u.geometry || u.area <= 0) {
        await Territory.deleteOne({ _id: u.id });
      } else {
        await Territory.updateOne(
          { _id: u.id },
          { $set: { geometry: u.geometry, area: u.area } },
        );
      }
    }

    // Upsert the capturer's (grown) territory.
    let userName = mine && mine.userName;
    if (!userName) {
      const u = await User.findById(userId).select('name').lean();
      userName = (u && u.name) || 'Runner';
    }

    // Best-effort push to everyone whose land was contested this run.
    for (const u of result.updatedOthers) {
      const victim = othersById.get(String(u.id));
      if (!victim) continue;
      const lost = !u.geometry || u.area <= 0;
      notifyUser(victim.userId, {
        title: lost ? 'Territory lost!' : 'Your territory is under attack',
        body: lost
          ? `${userName} took over your territory. Run to reclaim it!`
          : `${userName} captured part of your territory. Defend your turf!`,
        data: { type: 'territory' },
      });
    }
    await Territory.updateOne(
      { userId, season },
      {
        $set: {
          geometry: result.capturerGeometry,
          area: result.capturerArea,
          userName,
          season,
        },
      },
      { upsert: true },
    );

    res.json({
      success: true,
      area: result.capturerArea, // caller's new total
      claimed: areaOf(newPoly.geometry), // area enclosed by this run's loop
    });
  } catch (error) {
    console.error('Territory capture error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

module.exports = router;
