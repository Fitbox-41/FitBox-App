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

module.exports = { isConfigured, sendToTokens, sendToUser, notifyUser };
