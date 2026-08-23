// Point expiry — 99 days from the day a point is earned, consumed oldest-first.
//
// Each credit carries `remaining` (how much of it is still unspent) and
// `expiresAt`. A debit eats the oldest live credits first, so points genuinely
// expire in the order they were earned rather than the balance being one opaque
// number. Expiry itself is a real ledger entry, not a silent decrement, so a
// customer asking "where did my points go?" can be answered from the history.
//
// There is no scheduler in this project, so the sweep runs lazily whenever a
// wallet is read (the same pattern as weekly season settlement) plus a
// service-key endpoint for sweeping everyone.
const mongoose = require('mongoose');
const User = require('./models/User');
const WalletTransaction = require('./models/WalletTransaction');

const EXPIRY_DAYS = 99;

/// When a credit issued now should expire.
function creditExpiry(from = new Date()) {
  const d = new Date(from);
  d.setUTCDate(d.getUTCDate() + EXPIRY_DAYS);
  return d;
}

/// Expires anything past its date for one user, writing a debit per expired
/// credit so the history explains the drop. Idempotent: the ledger key is
/// derived from the credit, so re-running changes nothing.
///
/// Returns the number of points expired.
async function expireUserPoints(userId) {
  const now = new Date();
  const stale = await WalletTransaction.find({
    userId,
    type: 'credit',
    remaining: { $gt: 0 },
    expiresAt: { $lte: now },
  })
    .sort({ createdAt: 1 })
    .lean();

  if (!stale.length) return 0;

  let expired = 0;
  for (const credit of stale) {
    const amount = Number(credit.remaining) || 0;
    if (amount <= 0) continue;

    // Zero it first: if the ledger write below fails, the worst case is points
    // that are gone from the balance but lack a history row — far better than
    // the reverse, where a retry could debit the same points twice.
    const claimed = await WalletTransaction.updateOne(
      { _id: credit._id, remaining: { $gt: 0 } },
      { $set: { remaining: 0 } },
    );
    if (!claimed.modifiedCount) continue; // another sweep got there first

    const updated = await User.findByIdAndUpdate(
      userId,
      { $inc: { walletBalance: -amount } },
      { new: true },
    );

    try {
      await WalletTransaction.create({
        userId,
        type: 'debit',
        amount,
        balanceAfter: updated ? updated.walletBalance || 0 : 0,
        source: 'points_expired',
        sourceId: String(credit._id),
        idempotencyKey: 'expire_' + String(credit._id),
        description: `${amount} points expired ${EXPIRY_DAYS} days after being earned`,
      });
    } catch (e) {
      if (!e || e.code !== 11000) throw e; // 11000 = already recorded
    }
    expired += amount;
  }
  return expired;
}

/// Marks `amount` points as spent, oldest live credit first.
///
/// Call this alongside the balance decrement when points are redeemed, so the
/// FIFO buckets stay in step with the balance. Best-effort by design: if the
/// buckets can't cover the amount (legacy credits with no `remaining`), the
/// redemption still stands — the balance is the authority for what the customer
/// can spend, this only decides which points expire next.
async function consumeOldestFirst(userId, amount) {
  let left = Number(amount) || 0;
  if (left <= 0) return 0;

  const live = await WalletTransaction.find({
    userId,
    type: 'credit',
    remaining: { $gt: 0 },
    $or: [{ expiresAt: { $gt: new Date() } }, { expiresAt: { $exists: false } }],
  })
    .sort({ createdAt: 1 })
    .lean();

  for (const credit of live) {
    if (left <= 0) break;
    const take = Math.min(left, Number(credit.remaining) || 0);
    if (take <= 0) continue;
    await WalletTransaction.updateOne(
      { _id: credit._id },
      { $inc: { remaining: -take } },
    );
    left -= take;
  }
  return (Number(amount) || 0) - left; // how much was actually attributed
}

/// Points that will expire within `days`, for a "use them or lose them" nudge.
async function expiringSoon(userId, days = 14) {
  const now = new Date();
  const until = new Date(now.getTime() + days * 86400000);
  const rows = await WalletTransaction.find({
    userId,
    type: 'credit',
    remaining: { $gt: 0 },
    expiresAt: { $gt: now, $lte: until },
  })
    .sort({ expiresAt: 1 })
    .lean();

  const points = rows.reduce((sum, r) => sum + (Number(r.remaining) || 0), 0);
  return { points, nextExpiryAt: rows.length ? rows[0].expiresAt : null };
}

/// Gives existing credits a `remaining` and an `expiresAt`. Needed once, for
/// points issued before expiry existed; safe to re-run.
async function backfill() {
  const res = await WalletTransaction.updateMany(
    { type: 'credit', remaining: { $exists: false } },
    [
      {
        $set: {
          remaining: '$amount',
          expiresAt: {
            $add: [
              { $ifNull: ['$createdAt', new Date()] },
              EXPIRY_DAYS * 24 * 60 * 60 * 1000,
            ],
          },
        },
      },
    ],
  );
  return res.modifiedCount || 0;
}

module.exports = {
  EXPIRY_DAYS,
  creditExpiry,
  expireUserPoints,
  consumeOldestFirst,
  expiringSoon,
  backfill,
  coll: (n) => mongoose.connection.db.collection(n),
};
