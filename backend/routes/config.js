// Runtime configuration the app reads at startup.
//
// The points economy is set in the admin portal and stored in the shared
// `settings` document, so the rate and redemption limit can change without a
// mobile app release. The app renders whatever this returns — including the T&C
// wording — instead of shipping the numbers in the binary.
const express = require('express');
const mongoose = require('mongoose');

const router = express.Router();

// Used until an admin saves settings, or if the read fails. Must match
// FitBox_Website/Backend/Utils/points.js and seasonRewards.js.
const DEFAULT_POINT_VALUE_INR = 0.1;
const DEFAULT_REDEEM_CAP_PERCENT = 10;
const DEFAULT_SEASON_TOP_REWARD_INR = 200;

async function readPointsConfig() {
  try {
    const settings = await mongoose.connection.db.collection('settings').findOne({});
    const v = Number(settings && settings.pointValueInr);
    const c = Number(settings && settings.redeemCapPercent);
    const r = Number(settings && settings.seasonTopRewardInr);
    return {
      pointValueInr: Number.isFinite(v) && v > 0 ? v : DEFAULT_POINT_VALUE_INR,
      redeemCapPercent:
        Number.isFinite(c) && c >= 0 && c <= 100 ? c : DEFAULT_REDEEM_CAP_PERCENT,
      // 0 is meaningful (prizes switched off), so only fall back when unset.
      seasonTopRewardInr:
        Number.isFinite(r) && r >= 0 ? r : DEFAULT_SEASON_TOP_REWARD_INR,
    };
  } catch (_) {
    return {
      pointValueInr: DEFAULT_POINT_VALUE_INR,
      redeemCapPercent: DEFAULT_REDEEM_CAP_PERCENT,
      seasonTopRewardInr: DEFAULT_SEASON_TOP_REWARD_INR,
    };
  }
}

// Public: the app needs this before/without a signed-in user, and it contains
// nothing sensitive — it's the same information published in the Terms.
router.get('/points', async (req, res) => {
  try {
    const config = await readPointsConfig();
    res.json({
      success: true,
      ...config,
      // Rendered verbatim in the app's wallet T&C so the published wording
      // follows the configured numbers automatically.
      terms: [
        `Each point has a redemption value of ₹${config.pointValueInr.toFixed(2)} when applied to an eligible order. This value is for redemption only.`,
        'Points are not money, carry no cash value, and cannot be transferred, sold, exchanged for cash, or withdrawn.',
        `Points may be redeemed for a discount of up to ${config.redeemCapPercent}% of an order's value. The remaining balance must be paid using a standard payment method.`,
        'Points are earned in two ways. Every run you save earns points for the distance covered. Separately, a weekly competition runs Monday to Monday (UTC): when it closes, players are ranked by how much new territory they claimed during that week and only the top 20 receive a prize, the highest rank receiving the largest award.',
        'Points expire 99 days after the day they are earned. Points are spent oldest first, so the points closest to expiring are always used before newer ones. Expired points cannot be restored.',
        'Points are credited for genuine in-app activity only. We do not sync or reward activity from third-party services such as Apple Health or Google Health Connect. Activity recorded at a speed that is not plausibly running may not be rewarded.',
        'We may change the earn rate, redemption value, redemption limit, or expire unused points, and may modify or discontinue the programme, at any time with or without notice.',
        'We may withhold, reduce, or revoke points and suspend accounts where we reasonably suspect fraud, error, abuse, or any breach of these terms.',
        'If an order paid partly with points is cancelled or refunded, the redeemed points are returned to your wallet.',
      ],
    });
  } catch (error) {
    console.error('Points config error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

module.exports = router;
module.exports.readPointsConfig = readPointsConfig;
