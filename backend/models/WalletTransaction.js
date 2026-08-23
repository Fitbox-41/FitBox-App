const mongoose = require('mongoose');

const WalletTransactionSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    required: true,
    ref: 'User'
  },
  type: {
    type: String,
    enum: ['credit', 'debit'],
    required: true
  },
  amount: {
    type: Number,
    required: true
  },
  balanceAfter: {
    type: Number,
    required: true
  },
  source: {
    type: String,
    required: true // e.g., 'run_reward', 'territory_reward', 'checkout_redeem'
  },
  sourceId: {
    type: String, // ID related to the source (e.g. orderId, runId)
  },
  idempotencyKey: {
    type: String,
    required: true,
    unique: true
  },
  description: {
    type: String
  },
  // --- Point expiry (99 days from the day the points were earned) ---------
  // Credits only. `remaining` is how much of this credit is still unspent;
  // debits consume the oldest live credit first, so points expire in the order
  // they were earned. Absent on rows written before expiry existed — the
  // appmaint backfill fills them in.
  remaining: {
    type: Number
  },
  expiresAt: {
    type: Date
  }
}, { timestamps: true });

// Sweeping expired points and walking credits oldest-first both filter on
// (userId, type, remaining) and order by date — index it so neither scans.
WalletTransactionSchema.index({ userId: 1, type: 1, remaining: 1, expiresAt: 1 });

// Explicit shared-DB collection name. Must match the website + admin exactly so
// the wallet ledger is a single source of truth (coordinated with Diwakar).
module.exports = mongoose.model('WalletTransaction', WalletTransactionSchema, 'wallet_transactions');
