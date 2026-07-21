const mongoose = require('mongoose');

// Minimal view of the SHARED `users` collection (owned by the website). We only
// read/update the wallet balance here; `strict: false` means we never touch or
// clobber the website's other user fields. Balance now lives on the user doc
// (Diwakar's request) so it's visible right in the `users` collection.
const UserSchema = new mongoose.Schema(
  {
    walletBalance: { type: Number, default: 0 },
  },
  { strict: false, collection: 'users' }
);

module.exports = mongoose.models.User || mongoose.model('User', UserSchema, 'users');
