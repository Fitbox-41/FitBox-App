// Account deletion.
//
// Google Play requires an app that lets people create an account to let them
// start deleting it **from inside the app** as well as from a web page. The
// website already had a delete button, but it removed only the `users`
// document — every run, territory, wallet row and notification this app writes
// is keyed by `userId` and was left behind. Declaring "your data is deleted" on
// the Play data-safety form while a person's GPS routes survive would be false,
// so deletion is done here, where the app's own collections are known.
//
// The same endpoint is what the website's delete should eventually call; until
// then the app is the complete path.
const express = require('express');
const mongoose = require('mongoose');
const auth = require('../middleware/auth');

const User = require('../models/User');
const Run = require('../models/Run');
const Territory = require('../models/Territory');
const SeasonProgress = require('../models/SeasonProgress');
const WalletTransaction = require('../models/WalletTransaction');
const Notification = require('../models/Notification');
const ChallengeProgress = require('../models/ChallengeProgress');

const router = express.Router();

/// Everything this app stores about a person, and nothing that belongs to the
/// business. Orders are deliberately absent: a completed order is the shop's
/// financial record, and is retained (and anonymised by the user going away)
/// rather than erased — the same position every store takes.
const OWNED_BY_USER = [
  ['runs', Run],
  ['territories', Territory],
  ['seasonProgress', SeasonProgress],
  ['walletTransactions', WalletTransaction],
  ['notifications', Notification],
  ['challengeProgress', ChallengeProgress],
];

/// Deletes the signed-in user's data, then the account itself.
///
/// The data goes first and the account last: if this dies halfway, the person
/// is left with an account and less data, and can retry. The reverse order
/// would orphan the data with no way to reach it.
router.delete('/', auth, async (req, res) => {
  const userId = req.user.id || req.user._id;
  if (!userId || !mongoose.Types.ObjectId.isValid(String(userId))) {
    return res.status(400).json({ success: false, message: 'Invalid session' });
  }

  try {
    const deleted = {};
    for (const [name, Model] of OWNED_BY_USER) {
      const r = await Model.deleteMany({ userId });
      deleted[name] = r.deletedCount || 0;
    }

    const account = await User.deleteOne({ _id: userId });
    deleted.account = account.deletedCount || 0;

    // A token for a user who no longer exists is useless, but say so plainly
    // rather than pretending we deleted something.
    if (!deleted.account) {
      return res.status(404).json({
        success: false,
        message: 'That account no longer exists.',
        deleted,
      });
    }

    console.log('Account deleted', String(userId), JSON.stringify(deleted));
    res.json({ success: true, deleted });
  } catch (err) {
    console.error('Account deletion failed:', err.message);
    res.status(500).json({
      success: false,
      message: 'Could not delete the account. Nothing was lost — please try again.',
    });
  }
});

/// The name and tag a player shows on the territory map.
///
/// Deliberately separate from the account's real name, which belongs to the
/// shop and appears on orders. A player renaming themselves on the map must not
/// rename the person their delivery is addressed to, so these live in their own
/// fields on the shared user document (`strict: false`, so the website's schema
/// is untouched).
const MAX_DISPLAY_NAME = 24;
const MAX_TAG = 12;

/// A tag is a short badge next to the name on the map — a clan, a gym, a
/// nickname. Kept to plain characters so it can't smuggle markup or an
/// invisible-character name into every other player's screen.
const TAG_ALLOWED = /^[A-Za-z0-9 .'&-]*$/;

router.get('/profile', auth, async (req, res) => {
  try {
    const userId = req.user.id || req.user._id;
    const u = await User.findById(userId).select('name displayName tag photoUrl').lean();
    if (!u) return res.status(404).json({ success: false, message: 'Not found' });
    res.json({
      success: true,
      profile: {
        accountName: u.name || '',
        displayName: u.displayName || '',
        tag: u.tag || '',
        photoUrl: u.photoUrl || null,
        // What the map will actually show, so the app never has to guess.
        effectiveName: u.displayName || u.name || 'Runner',
      },
    });
  } catch (err) {
    console.error('Profile read failed:', err.message);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

router.patch('/profile', auth, async (req, res) => {
  try {
    const userId = req.user.id || req.user._id;
    const body = req.body || {};
    const set = {};

    if (body.displayName !== undefined) {
      const name = String(body.displayName).trim().slice(0, MAX_DISPLAY_NAME);
      if (name && !TAG_ALLOWED.test(name)) {
        return res.status(400).json({
          success: false,
          message: "A display name can use letters, numbers, spaces and . ' & - only.",
        });
      }
      set.displayName = name; // empty string clears it, falling back to the account name
    }

    if (body.tag !== undefined) {
      const tag = String(body.tag).trim().slice(0, MAX_TAG);
      if (tag && !TAG_ALLOWED.test(tag)) {
        return res.status(400).json({
          success: false,
          message: "A tag can use letters, numbers, spaces and . ' & - only.",
        });
      }
      set.tag = tag;
    }

    if (!Object.keys(set).length) {
      return res.status(400).json({ success: false, message: 'Nothing to update' });
    }

    const u = await User.findByIdAndUpdate(userId, { $set: set }, { new: true })
      .select('name displayName tag')
      .lean();
    if (!u) return res.status(404).json({ success: false, message: 'Not found' });

    const effectiveName = u.displayName || u.name || 'Runner';
    // The map reads a denormalised copy on the territory, so refresh it now —
    // otherwise a rename wouldn't show until the player's next run.
    await Territory.updateOne({ userId }, { $set: { userName: effectiveName, tag: u.tag || '' } });
    await SeasonProgress.updateMany({ userId }, { $set: { userName: effectiveName } });

    res.json({
      success: true,
      profile: {
        accountName: u.name || '',
        displayName: u.displayName || '',
        tag: u.tag || '',
        effectiveName,
      },
    });
  } catch (err) {
    console.error('Profile update failed:', err.message);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

module.exports = router;
