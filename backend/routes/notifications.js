// The user's own notification history — the events that were pushed to them
// (territory contested, season settled, challenge reward). Written by
// fcm.notifyUser, so this list survives push being off or a missed banner.
const express = require('express');
const auth = require('../middleware/auth');
const Notification = require('../models/Notification');

const router = express.Router();

// GET /api/notifications — newest first, with the unread count for the badge.
router.get('/', auth, async (req, res) => {
  try {
    const userId = req.user.id || req.user._id;
    const limit = Math.min(Number(req.query.limit) || 50, 100);

    const [items, unread] = await Promise.all([
      Notification.find({ userId }).sort({ createdAt: -1 }).limit(limit).lean(),
      Notification.countDocuments({ userId, read: false }),
    ]);

    res.json({
      success: true,
      unread,
      notifications: items.map((n) => ({
        id: String(n._id),
        type: n.type || 'system',
        title: n.title,
        body: n.body || '',
        data: n.data || {},
        read: !!n.read,
        createdAt: n.createdAt,
      })),
    });
  } catch (error) {
    console.error('Notifications fetch error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// POST /api/notifications/read — mark everything read (or one, with { id }).
router.post('/read', auth, async (req, res) => {
  try {
    const userId = req.user.id || req.user._id;
    const id = req.body && req.body.id;
    const filter = id ? { _id: id, userId } : { userId, read: false };
    const result = await Notification.updateMany(filter, { $set: { read: true } });
    res.json({ success: true, updated: result.modifiedCount || 0 });
  } catch (error) {
    console.error('Notifications read error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

module.exports = router;
