const express = require('express');
const mongoose = require('mongoose');
const auth = require('../middleware/auth');
const serviceAuth = require('../middleware/serviceAuth');
const User = require('../models/User');
const WalletTransaction = require('../models/WalletTransaction');

const router = express.Router();

// ---------------------------------------------------------------------------
// Shared ledger mutation.
//
// The balance lives on the user document (`users.walletBalance`); every change
// is also appended to the `wallet_transactions` ledger. Both happen atomically
// inside one MongoDB transaction, so balance always equals the ledger sum.
// Idempotent: a repeat with the same idempotencyKey returns the original
// transaction and never double-applies. Throws { status, message }.
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

    // Atomically move the balance on the user doc. For a debit, the filter
    // guarantees we never go negative (and covers a missing user).
    let updatedUser;
    if (type === 'debit') {
      updatedUser = await User.findOneAndUpdate(
        { _id: userId, walletBalance: { $gte: amount } },
        { $inc: { walletBalance: -amount } },
        { new: true, session }
      );
      if (!updatedUser) {
        await session.abortTransaction();
        session.endSession();
        throw { status: 400, message: 'Insufficient balance' };
      }
    } else {
      updatedUser = await User.findByIdAndUpdate(
        userId,
        { $inc: { walletBalance: amount } },
        { new: true, session }
      );
      if (!updatedUser) {
        await session.abortTransaction();
        session.endSession();
        throw { status: 404, message: 'User not found' };
      }
    }

    const newBalance = updatedUser.walletBalance;
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
// transactions). Balance comes from the user doc; history from the ledger.
// ---------------------------------------------------------------------------
router.get('/', auth, async (req, res) => {
  try {
    const userId = req.user.id || req.user._id;
    const user = await User.findById(userId).select('walletBalance');
    const balance = user && user.walletBalance ? user.walletBalance : 0;
    const transactions = await WalletTransaction.find({ userId }).sort({ createdAt: -1 });
    res.json({ success: true, balance, transactions });
  } catch (error) {
    console.error('Wallet read error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// ---------------------------------------------------------------------------
// POST /api/wallet/credit  — SERVER-TO-SERVER ONLY (WALLET_SERVICE_KEY).
// Credits points to a user (admin adjust / territory / run rewards).
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
// Debits points (website checkout). 400 "Insufficient balance" instead of
// going negative. Idempotent per order.
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

// ---------------------------------------------------------------------------
// POST /api/wallet/reconcile  — SERVER-TO-SERVER ONLY (WALLET_SERVICE_KEY).
// Recomputes every user's walletBalance from the ledger (source of truth) and
// writes it to the user doc. Used to migrate from the old `wallets` collection
// and as an integrity/repair tool. Optional body { userId } returns that user's
// balance for verification.
// ---------------------------------------------------------------------------
router.post('/reconcile', serviceAuth, async (req, res) => {
  try {
    const sums = await WalletTransaction.aggregate([
      {
        $group: {
          _id: '$userId',
          balance: {
            $sum: {
              $cond: [{ $eq: ['$type', 'credit'] }, '$amount', { $multiply: ['$amount', -1] }],
            },
          },
        },
      },
    ]);

    let usersUpdated = 0;
    for (const row of sums) {
      await User.updateOne(
        { _id: row._id },
        { $set: { walletBalance: Math.max(0, row.balance) } }
      );
      usersUpdated += 1;
    }

    let checked;
    if (req.body && req.body.userId && mongoose.Types.ObjectId.isValid(req.body.userId)) {
      const u = await User.findById(req.body.userId).select('walletBalance');
      checked = { userId: req.body.userId, balance: u ? u.walletBalance || 0 : null };
    }

    res.json({ success: true, usersUpdated, checked });
  } catch (error) {
    console.error('Reconcile error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

module.exports = router;
