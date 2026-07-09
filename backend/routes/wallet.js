const express = require('express');
const mongoose = require('mongoose');
const auth = require('../middleware/auth');
const Wallet = require('../models/Wallet');
const WalletTransaction = require('../models/WalletTransaction');

const router = express.Router();

// Get wallet balance and transactions
router.get('/', auth, async (req, res) => {
  try {
    // Determine user ID from token
    const userId = req.user.id || req.user._id;

    let wallet = await Wallet.findOne({ userId });
    
    if (!wallet) {
      wallet = new Wallet({ userId, balance: 0 });
      await wallet.save();
    }

    const transactions = await WalletTransaction.find({ userId }).sort({ createdAt: -1 });

    res.json({
      success: true,
      balance: wallet.balance,
      transactions
    });
  } catch (error) {
    console.error('Wallet error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Idempotent point crediting
router.post('/credit', auth, async (req, res) => {
  const session = await mongoose.startSession();
  session.startTransaction();
  try {
    const userId = req.user.id || req.user._id;
    const { amount, source, sourceId, idempotencyKey, description } = req.body;

    if (!amount || amount <= 0) {
      throw new Error('Invalid credit amount');
    }

    // Check idempotency
    const existingTx = await WalletTransaction.findOne({ idempotencyKey }).session(session);
    if (existingTx) {
      await session.abortTransaction();
      session.endSession();
      // Return the existing transaction for idempotency
      return res.json({ success: true, message: 'Already processed', transaction: existingTx });
    }

    let wallet = await Wallet.findOne({ userId }).session(session);
    if (!wallet) {
      wallet = new Wallet({ userId, balance: 0 });
    }

    const newBalance = wallet.balance + amount;
    wallet.balance = newBalance;
    await wallet.save({ session });

    const tx = new WalletTransaction({
      userId,
      type: 'credit',
      amount,
      balanceAfter: newBalance,
      source,
      sourceId,
      idempotencyKey,
      description
    });
    await tx.save({ session });

    await session.commitTransaction();
    session.endSession();

    res.json({
      success: true,
      balance: newBalance,
      transaction: tx
    });
  } catch (error) {
    await session.abortTransaction();
    session.endSession();
    console.error('Credit error:', error);
    res.status(500).json({ success: false, message: error.message || 'Server error' });
  }
});

module.exports = router;
