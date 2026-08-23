// Firebase Cloud Messaging sender (server side).
//
// Credentials come from the FIREBASE_SERVICE_ACCOUNT env var — the Firebase
// Admin service-account JSON, either as raw JSON or base64-encoded (handy for
// Vercel env vars). If it isn't set, every send is a safe no-op so the rest of
// the API keeps working; push simply stays dark until the key is configured.
const admin = require('firebase-admin');
const User = require('./models/User');
const Notification = require('./models/Notification');

let cachedApp; // memoized across warm serverless invocations
let triedInit = false;

function getApp() {
  if (cachedApp) return cachedApp;
  if (triedInit) return null;
  triedInit = true;

  const raw = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (!raw) return null;

  let creds;
  try {
    creds = JSON.parse(raw);
  } catch (_) {
    try {
      creds = JSON.parse(Buffer.from(raw, 'base64').toString('utf8'));
    } catch (err) {
      console.error('FIREBASE_SERVICE_ACCOUNT is not valid JSON/base64:', err.message);
      return null;
    }
  }

  try {
    cachedApp = admin.apps.length
      ? admin.app()
      : admin.initializeApp({ credential: admin.credential.cert(creds) });
    return cachedApp;
  } catch (err) {
    console.error('Firebase admin init failed:', err.message);
    return null;
  }
}

function isConfigured() {
  return !!getApp();
}

// Send to a raw list of device tokens. Returns { sent, invalid } where `invalid`
// are tokens FCM reports as dead (unregistered / malformed) so callers can prune.
async function sendToTokens(tokens, { title, body, data } = {}) {
  const app = getApp();
  const list = (tokens || []).filter(Boolean);
  if (!app || list.length === 0) return { sent: 0, invalid: [] };

  const message = {
    notification: { title, body },
    data: Object.fromEntries(
      Object.entries(data || {}).map(([k, v]) => [k, String(v)]),
    ),
    android: { priority: 'high' },
    apns: { payload: { aps: { sound: 'default' } } },
    tokens: list,
  };

  const res = await admin.messaging().sendEachForMulticast(message);
  const invalid = [];
  res.responses.forEach((r, i) => {
    if (!r.success) {
      const code = (r.error && r.error.code) || '';
      if (
        code.includes('registration-token-not-registered') ||
        code.includes('invalid-argument') ||
        code.includes('invalid-registration-token')
      ) {
        invalid.push(list[i]);
      }
    }
  });
  return { sent: res.successCount, invalid };
}

// Send to one user (looks up their device tokens, prunes dead ones).
async function sendToUser(userId, msg) {
  const app = getApp();
  if (!app) return { sent: 0 };
  const u = await User.findById(userId).select('fcmTokens').lean();
  const tokens = (u && u.fcmTokens) || [];
  if (!tokens.length) return { sent: 0 };
  const { sent, invalid } = await sendToTokens(tokens, msg);
  if (invalid.length) {
    await User.updateOne({ _id: userId }, { $pull: { fcmTokens: { $in: invalid } } });
  }
  return { sent };
}

// Best-effort push that never throws into the caller's request flow (used for
// event notifications like "your territory was taken").
//
// It also records the event so the in-app Notifications list shows it even when
// push is unconfigured, the device has no token registered yet, or the user
// dismissed the system notification. Pass { persist: false } for things that
// shouldn't appear in that history (e.g. an admin broadcast test).
function notifyUser(userId, msg) {
  const { persist = true, ...push } = msg || {};

  if (persist) {
    Notification.create({
      userId,
      type: (push.data && push.data.type) || 'system',
      title: push.title,
      body: push.body || '',
      data: push.data || {},
    }).catch((err) =>
      console.error('Notification persist failed:', err.message),
    );
  }

  sendToUser(userId, push).catch((err) =>
    console.error('Push notifyUser failed:', err.message),
  );
}

/// Announces something to every app user — push where a device is registered,
/// and an in-app notification for everyone, so a user who has push disabled (or
/// hasn't opened the app since installing) still sees it in their list.
///
/// The audience is app users only: anyone with a registered device or who has
/// signed in from the app. Website-only customers are left out — they have no
/// use for a challenge announcement.
///
/// Best-effort by design: never throws, so an announcement failing can't take
/// down whatever triggered it.
async function notifyAllAppUsers({ title, body, data } = {}) {
  try {
    const users = await User.find({
      $or: [
        { fcmTokens: { $exists: true, $ne: [] } },
        { lastAppLoginAt: { $exists: true } },
      ],
    })
      .select('_id fcmTokens')
      .lean();

    if (!users.length) return { recipients: 0, sent: 0 };

    // In-app history first — it's the part that doesn't depend on push being
    // configured, so it should survive a push outage.
    try {
      await Notification.insertMany(
        users.map((u) => ({
          userId: u._id,
          type: (data && data.type) || 'system',
          title,
          body: body || '',
          data: data || {},
        })),
        { ordered: false },
      );
    } catch (err) {
      console.error('Broadcast notification persist failed:', err.message);
    }

    // Deduped: if the same device token is still attached to more than one
    // account, FCM would otherwise deliver the same broadcast to that phone
    // once per account.
    const tokens = [
      ...new Set(users.flatMap((u) => u.fcmTokens || []).filter(Boolean)),
    ];
    const { sent, invalid } = await sendToTokens(tokens, { title, body, data });
    if (invalid && invalid.length) {
      await User.updateMany(
        { fcmTokens: { $in: invalid } },
        { $pull: { fcmTokens: { $in: invalid } } },
      );
    }
    return { recipients: users.length, sent };
  } catch (err) {
    console.error('notifyAllAppUsers failed:', err.message);
    return { recipients: 0, sent: 0 };
  }
}

module.exports = {
  isConfigured,
  sendToTokens,
  sendToUser,
  notifyUser,
  notifyAllAppUsers,
};
