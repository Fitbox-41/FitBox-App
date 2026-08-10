// Server-to-server authentication for wallet MUTATIONS.
//
// Points convert to real store value, so an end-user client must never be able
// to credit or debit a wallet directly. Only trusted backends may:
//   - the website checkout server (redeem points at checkout),
//   - the admin backend / a future territory-reward service (credit points).
// Those callers hold the shared WALLET_SERVICE_KEY and pass the target userId
// explicitly. End-user clients can only READ their own wallet (see auth.js).
const crypto = require('crypto');

module.exports = function serviceAuth(req, res, next) {
  const configured = process.env.WALLET_SERVICE_KEY;
  if (!configured) {
    // Fail closed: if the key isn't configured, mutations are disabled rather
    // than open to anyone.
    return res
      .status(503)
      .json({ success: false, message: 'Wallet mutations are not configured' });
  }

  const provided = req.headers['x-service-key'];
  if (!provided || !safeEqual(String(provided), String(configured))) {
    return res
      .status(403)
      .json({ success: false, message: 'Service authentication required' });
  }

  next();
};

// Constant-time comparison so the response time can't be used to discover the
// key a character at a time. Length is compared first via hashing, because
// timingSafeEqual throws on mismatched lengths.
function safeEqual(a, b) {
  const ha = crypto.createHash('sha256').update(a).digest();
  const hb = crypto.createHash('sha256').update(b).digest();
  return crypto.timingSafeEqual(ha, hb);
}
