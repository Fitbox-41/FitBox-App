const jwt = require('jsonwebtoken');
const User = require('../models/User');

// Only the mobile app talks to this backend, so any authenticated request proves
// the user is active on the app. Stamp `lastAppLoginAt` (throttled to once/hour,
// fire-and-forget) so the admin portal can tell app users from website-only ones.
const APP_SEEN_THROTTLE_MS = 60 * 60 * 1000;
function stampAppSeen(userId) {
  if (!userId) return;
  const cutoff = new Date(Date.now() - APP_SEEN_THROTTLE_MS);
  User.updateOne(
    {
      _id: userId,
      $or: [{ lastAppLoginAt: { $exists: false } }, { lastAppLoginAt: { $lt: cutoff } }],
    },
    { $set: { lastAppLoginAt: new Date() } },
  ).catch(() => {});
}

const auth = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ success: false, message: 'Authentication required' });
    }

    const token = authHeader.split(' ')[1];

    // Website uses JWT_SECRET, we must use the same. The algorithm is pinned:
    // without it a token could ask to be verified a different way, and only
    // HS256 is ever issued.
    const decoded = jwt.verify(token, process.env.JWT_SECRET, {
      algorithms: ['HS256'],
    });

    // Attach the user info from token to the request
    // Assumes token contains { id: '...userId...' } based on standard MERN practice
    req.user = decoded;
    stampAppSeen(decoded.id || decoded._id);

    next();
  } catch (error) {
    console.error('Auth error:', error.message);
    res.status(401).json({ success: false, message: 'Invalid or expired token' });
  }
};

module.exports = auth;
