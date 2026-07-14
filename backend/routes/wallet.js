const express = require('express');
const mongoose = require('mongoose');
const auth = require('../middleware/auth');
const serviceAuth = require('../middleware/serviceAuth');
const Wallet = require('../models/Wallet');
const WalletTransaction = require('../models/WalletTransaction');

const router = express.Router();

// ---------------------------------------------------------------------------
// Shared ledger mutation.
//
// Applies a single credit or debit atomically inside a MongoDB transaction so
// the wallet balance always equals the sum of the ledger. Idempotent: a repeat
// with the same idempotencyKey returns the original transaction and never
// double-applies. Throws { status, message } for the caller to map to a
// response.
// ---------------------------------------------------------------------------
async function applyLedgerEntry({ userId, type, amount, source, sourceId, idempotencyKey, description }) {
  if (!mongoose.Types.ObjectId.isValid(userId)) {
    throw { status: 400, message: 'Valid userId is required' };
  }
  if (!Number.isFinite(amount) || amount <= 0) {
    throw { status: 400, message: 'amount must be a positive number' };
  }
  if (!source) {
    throw { status: 400, message: 'source is required' };
  }
  if (!idempotencyKey) {
    throw { status: 400, message: 'idempotencyKey is required' };
  }

  const session = await mongoose.startSession();
  session.startTransaction();
  try {
    // Idempotency: if we've already recorded this key, return it unchanged.
    const existing = await WalletTransaction.findOne({ idempotencyKey }).session(session);
    if (existing) {
      await session.abortTransaction();
      session.endSession();
      return { alreadyProcessed: true, transaction: existing };
    }

    let wallet = await Wallet.findOne({ userId }).session(session);
    if (!wallet) {
      wallet = new Wallet({ userId, balance: 0 });
    }

    const delta = type === 'debit' ? -amount : amount;
    const newBalance = wallet.balance + delta;
    if (newBalance < 0) {
      await session.abortTransaction();
      session.endSession();
      throw { status: 400, message: 'Insufficient balance' };
    }

    wallet.balance = newBalance;
    await wallet.save({ session });

    const tx = new WalletTransaction({
      userId,
      type,
      amount,
      balanceAfter: newBalance,
      source,
      sourceId,
      idempotencyKey,
      description,
    });
    await tx.save({ session });

    await session.commitTransaction();
    session.endSession();
    return { alreadyProcessed: false, balance: newBalance, transaction: tx };
  } catch (error) {
    await session.abortTransaction().catch(() => {});
    session.endSession();

    // Concurrent requests with the same idempotencyKey can both pass the
    // findOne check and race to insert; the unique index rejects the loser
    // with a duplicate-key error. Treat that as already-processed.
    if (error && error.code === 11000) {
      const existing = await WalletTransaction.findOne({ idempotencyKey });
      if (existing) return { alreadyProcessed: true, transaction: existing };
    }
    throw error;
  }
}

// ---------------------------------------------------------------------------
// GET /api/wallet  — the signed-in user reads their OWN wallet (balance +
// transactions). This is the only wallet route an end-user client may call.
// ---------------------------------------------------------------------------
router.get('/', auth, async (req, res) => {
  try {
    const userId = req.user.id || req.user._id;

    let wallet = await Wallet.findOne({ userId });
    if (!wallet) {
      wallet = new Wallet({ userId, balance: 0 });
      await wallet.save();
    }

    const transactions = await WalletTransaction.find({ userId }).sort({ createdAt: -1 });

    res.json({ success: true, balance: wallet.balance, transactions });
  } catch (error) {
    console.error('Wallet read error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// ---------------------------------------------------------------------------
// POST /api/wallet/credit  — SERVER-TO-SERVER ONLY (WALLET_SERVICE_KEY).
// Credits points to a user. Called by trusted backends (admin adjust now;
// territory/run rewards later), never by an end-user client.
// Body: { userId, amount, source, sourceId?, idempotencyKey, description? }
// ---------------------------------------------------------------------------
router.post('/credit', serviceAuth, async (req, res) => {
  try {
    const { userId, amount, source, sourceId, idempotencyKey, description } = req.body;
    const result = await applyLedgerEntry({
      userId,
      type: 'credit',
      amount,
      source,
      sourceId,
      idempotencyKey,
      description,
    });
    if (result.alreadyProcessed) {
      return res.json({ success: true, message: 'Already processed', transaction: result.transaction });
    }
    res.json({ success: true, balance: result.balance, transaction: result.transaction });
  } catch (error) {
    const status = error && error.status ? error.status : 500;
    if (status === 500) console.error('Credit error:', error);
    res.status(status).json({ success: false, message: (error && error.message) || 'Server error' });
  }
});

// ---------------------------------------------------------------------------
// POST /api/wallet/redeem  — SERVER-TO-SERVER ONLY (WALLET_SERVICE_KEY).
// Debits points when a user redeems them (website checkout). Fails with 400
// "Insufficient balance" rather than going negative. Idempotent per order.
// Body: { userId, amount, source, sourceId?, idempotencyKey, description? }
//   (source is typically 'checkout_redeem', sourceId the orderId.)
// ---------------------------------------------------------------------------
router.post('/redeem', serviceAuth, async (req, res) => {
  try {
    const { userId, amount, source, sourceId, idempotencyKey, description } = req.body;
    const result = await applyLedgerEntry({
      userId,
      type: 'debit',
      amount,
      source: source || 'checkout_redeem',
      sourceId,
      idempotencyKey,
      description,
    });
    if (result.alreadyProcessed) {
      return res.json({ success: true, message: 'Already processed', transaction: result.transaction });
    }
    res.json({ success: true, balance: result.balance, transaction: result.transaction });
  } catch (error) {
    const status = error && error.status ? error.status : 500;
    if (status === 500) console.error('Redeem error:', error);
    res.status(status).json({ success: false, message: (error && error.message) || 'Server error' });
  }
});

module.exports = router;
