const express = require('express');
const cors = require('cors');
require('dotenv').config();

const connectDB = require('./db');
const walletRoutes = require('./routes/wallet');
const runsRoutes = require('./routes/runs');
const territoriesRoutes = require('./routes/territories');
const challengesRoutes = require('./routes/challenges');
const pushRoutes = require('./routes/push');
const appmaintRoutes = require('./routes/appmaint');
const configRoutes = require('./routes/config');
const notificationsRoutes = require('./routes/notifications');

const app = express();

// The mobile app isn't subject to CORS, so this only governs browsers: the
// Flutter web build and the admin portal. Anything else is refused rather than
// letting an arbitrary page call the API with a token it has got hold of.
const ALLOWED_ORIGINS = [
  'https://fitboxsports-8d1c0.web.app',
  'https://fitboxsports-8d1c0.firebaseapp.com',
  'https://fit-box-sports-website-efns.vercel.app',
  'http://localhost:3000',
  'http://localhost:5173',
];
app.use(
  cors({
    origin(origin, callback) {
      // No Origin header = a non-browser client (the mobile app, curl, a
      // server-to-server call) — those aren't what CORS protects against.
      if (!origin) return callback(null, true);
      if (ALLOWED_ORIGINS.includes(origin)) return callback(null, true);
      if (process.env.EXTRA_CORS_ORIGINS) {
        const extra = process.env.EXTRA_CORS_ORIGINS.split(',').map((s) => s.trim());
        if (extra.includes(origin)) return callback(null, true);
      }
      return callback(null, false);
    },
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Service-Key', 'X-Client'],
  }),
);

// Cap the request body: run routes are the only large payloads and a GPS trace
// is far below this, so anything bigger is abuse rather than use.
app.use(express.json({ limit: '1mb' }));

// Throttle per IP. Territory capture and run upload both do real geometry work,
// so an authenticated client hammering them is the cheapest way to burn the
// serverless budget. Written without a dependency to keep the function cold
// start small; Vercel gives each instance its own counter, which is enough to
// blunt a single abusive client.
const RATE_WINDOW_MS = 60 * 1000;
const RATE_MAX = 120; // per IP per minute across the API
const hits = new Map();
app.use('/api', (req, res, next) => {
  const key = req.headers['x-forwarded-for'] || req.ip || 'unknown';
  const now = Date.now();
  const entry = hits.get(key);
  if (!entry || now > entry.reset) {
    hits.set(key, { count: 1, reset: now + RATE_WINDOW_MS });
    return next();
  }
  entry.count += 1;
  if (entry.count > RATE_MAX) {
    res.set('Retry-After', Math.ceil((entry.reset - now) / 1000));
    return res.status(429).json({ success: false, message: 'Too many requests. Please slow down.' });
  }
  // Keep the map from growing without bound on a long-lived instance.
  if (hits.size > 5000) {
    for (const [k, v] of hits) if (now > v.reset) hits.delete(k);
  }
  next();
});

// Liveness probe — intentionally before the DB middleware so it reports the
// service is up even if the database is unreachable.
//
// It also reports which build is live. Every endpoint that would reveal that is
// behind auth, so without this there's no way to tell whether a push actually
// deployed — bump `apiVersion` when a change matters to the app.
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    service: 'FitBox App Backend',
    // Tracks the app release this backend is built for; both restarted at 1.0
    // for the first release.
    apiVersion: '1.0.0',
    // Capabilities the app can rely on, so a client can tell what it's talking
    // to instead of guessing from behaviour.
    features: {
      runClaimsTerritory: true, // POST /api/runs claims land server-side
      routeCorridorClaims: true, // claims a corridor, not just enclosed loops
      idempotentRuns: true, // clientId-based deduplication of re-uploads
      weeklySeasonRewards: true, // points paid on season close, not per run
      configurablePoints: true, // GET /api/config/points drives value + cap
    },
    commit: process.env.VERCEL_GIT_COMMIT_SHA
      ? String(process.env.VERCEL_GIT_COMMIT_SHA).slice(0, 7)
      : null,
    deployedAt: process.env.VERCEL_DEPLOYMENT_ID || null,
  });
});

// Ensure the database is connected before handling any API request. Safe on
// serverless (reuses a warm connection) and on a long-running server alike.
app.use(async (req, res, next) => {
  try {
    await connectDB();
    next();
  } catch (err) {
    console.error('MongoDB connection error:', err.message);
    res.status(503).json({ success: false, message: 'Database unavailable' });
  }
});

app.use('/api/wallet', walletRoutes);
app.use('/api/runs', runsRoutes);
app.use('/api/territories', territoriesRoutes);
app.use('/api/challenges', challengesRoutes);
app.use('/api/push', pushRoutes);
app.use('/api/appmaint', appmaintRoutes);
app.use('/api/config', configRoutes);
app.use('/api/notifications', notificationsRoutes);

// Only start a listener when run directly (local dev). On Vercel the exported
// app is wrapped as a serverless function, so app.listen must not run there.
if (require.main === module) {
  const PORT = process.env.PORT || 4000;
  app.listen(PORT, () => {
    console.log(`FitBox App Backend running on port ${PORT}`);
  });
}

module.exports = app;
