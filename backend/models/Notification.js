const mongoose = require('mongoose');

// An event worth telling one user about — territory taken, a season settled, a
// challenge reward claimed. Written whenever a push is sent, so the in-app list
// shows the same history even when push is off, the device has no token yet, or
// the notification was swiped away.
const NotificationSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true,
  },
  // Drives the icon/colour in the app: territory | season | challenge | wallet | system
  type: { type: String, default: 'system' },
  title: { type: String, required: true },
  body: { type: String, default: '' },
  // Free-form payload mirroring the push `data` (e.g. season, rank, points).
  data: { type: mongoose.Schema.Types.Mixed, default: {} },
  read: { type: Boolean, default: false },
}, { timestamps: true });

NotificationSchema.index({ userId: 1, createdAt: -1 });

module.exports = mongoose.model('Notification', NotificationSchema, 'notifications');
