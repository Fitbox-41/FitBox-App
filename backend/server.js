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

const app = express();

app.use(cors());
app.use(express.json());

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
    apiVersion: '1.18.0',
    // Capabilities the app can rely on, so a client can tell what it's talking
    // to instead of guessing from behaviour.
    features: {
      runClaimsTerritory: true, // POST /api/runs claims land server-side
      routeCorridorClaims: true, // claims a corridor, not just enclosed loops
      idempotentRuns: true, // clientId-based deduplication of re-uploads
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

// Only start a listener when run directly (local dev). On Vercel the exported
// app is wrapped as a serverless function, so app.listen must not run there.
if (require.main === module) {
  const PORT = process.env.PORT || 4000;
  app.listen(PORT, () => {
    console.log(`FitBox App Backend running on port ${PORT}`);
  });
}

module.exports = app;
