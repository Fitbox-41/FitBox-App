const express = require('express');
const auth = require('../middleware/auth');
const serviceAuth = require('../middleware/serviceAuth');
const User = require('../models/User');
const { isConfigured, sendToUser, sendToTokens } = require('../fcm');

const router = express.Router();

// Whether push sending is wired up (FIREBASE_SERVICE_ACCOUNT present). Public and
// leaks nothing — just a boolean the app/admin can use to show push status.
router.get('/status', (req, res) => {
  res.json({ success: true, configured: isConfigured() });
});

// Register this device's FCM token against the signed-in user. Idempotent —
// $addToSet dedupes, so re-registering on every launch is fine.
router.post('/register', auth, async (req, res) => {
  try {
    const userId = req.user.id || req.user._id;
    const token = (req.body && req.body.token || '').trim();
    if (!token) {
      return res.status(400).json({ success: false, message: 'token required' });
    }
    await User.updateOne(
      { _id: userId },
      { $addToSet: { fcmTokens: token } },
    );
    res.json({ success: true, pushConfigured: isConfigured() });
  } catch (error) {
    console.error('Push register error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Drop a token (sign-out / uninstall best-effort).
router.post('/unregister', auth, async (req, res) => {
  try {
    const userId = req.user.id || req.user._id;
    const token = (req.body && req.body.token || '').trim();
    if (token) {
      await User.updateOne({ _id: userId }, { $pull: { fcmTokens: token } });
    }
    res.json({ success: true });
  } catch (error) {
    console.error('Push unregister error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Admin push composer (service-key gated — used from the admin portal).
// Body: { title, body, data?, userId? | userIds? | all?: true }
router.post('/send', serviceAuth, async (req, res) => {
  try {
    if (!isConfigured()) {
      return res.status(503).json({
        success: false,
        message: 'Push is not configured (set FIREBASE_SERVICE_ACCOUNT).',
      });
    }
    const { title, body, data } = req.body || {};
    if (!title || !body) {
      return res.status(400).json({ success: false, message: 'title and body required' });
    }
    const msg = { title, body, data };

    // Broadcast to everyone who has a registered device.
    if (req.body.all) {
      const users = await User.find({ fcmTokens: { $exists: true, $ne: [] } })
        .select('fcmTokens')
        .lean();
      const tokens = users.flatMap((u) => u.fcmTokens || []);
      const { sent } = await sendToTokens(tokens, msg);
      return res.json({ success: true, recipients: users.length, sent });
    }

    // Targeted send.
    const ids = req.body.userIds || (req.body.userId ? [req.body.userId] : []);
    if (!ids.length) {
      return res
        .status(400)
        .json({ success: false, message: 'Provide all:true, userId, or userIds' });
    }
    let sent = 0;
    for (const id of ids) {
      const r = await sendToUser(id, msg);
      sent += r.sent;
    }
    res.json({ success: true, recipients: ids.length, sent });
  } catch (error) {
    console.error('Push send error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

module.exports = router;
