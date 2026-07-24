const express = require('express');
const auth = require('../middleware/auth');
const Territory = require('../models/Territory');
const User = require('../models/User');
const { routeToPolygon, applyCapture, areaOf } = require('../territoryEngine');

const router = express.Router();

// Every user's current territory — for the shared map (all users see all).
router.get('/', auth, async (req, res) => {
  try {
    const territories = await Territory.find({ area: { $gt: 0 } }).lean();
    res.json({
      success: true,
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

    const mine = await Territory.findOne({ userId });
    const others = await Territory.find({ userId: { $ne: userId } });

    const result = applyCapture(
      mine ? mine.geometry : null,
      others.map((o) => ({ id: o._id, geometry: o.geometry })),
      newPoly,
    );

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
    await Territory.updateOne(
      { userId },
      {
        $set: {
          geometry: result.capturerGeometry,
          area: result.capturerArea,
          userName,
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
