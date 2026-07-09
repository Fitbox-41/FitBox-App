const mongoose = require('mongoose');

const WalletSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    required: true,
    unique: true,
    ref: 'User'
  },
  balance: {
    type: Number,
    required: true,
    default: 0
  }
}, { timestamps: true });

// Explicit collection name so app, website and admin all read/write the same
// documents in the shared database (never rely on Mongoose auto-pluralization).
module.exports = mongoose.model('Wallet', WalletSchema, 'wallets');
