// End-of-season territory rewards.
//
// Points are NOT paid per run. A season (one ISO week) is a competition: when it
// closes, the leaderboard is settled and the top holders are paid by how much
// land they finished with — rank 1 takes the largest share, and only the top
// TOP_N are paid at all. That's what makes holding territory to Monday matter,
// rather than banking points the moment a run ends.
//
// The payout table is deliberately not shown in the app UI; it's disclosed in
// the points T&C.

const mongoose = require('mongoose');
const Territory = require('./models/Territory');
const WalletTransaction = require('./models/WalletTransaction');
const User = require('./models/User');

// Required lazily inside settleSeason: pulling in firebase-admin at module load
// would make computeSeasonRewards — a pure function — impossible to unit-test
// without the push stack installed.

const coll = (name) => mongoose.connection.db.collection(name);

// How many places are paid.
const TOP_N = 20;

// What finishing first is worth, in rupees — the fallback when settings haven't
// been saved. The live value is set in the admin portal
// (`settings.seasonTopRewardInr`); everything else scales down from it, so that
// one number sets the whole prize table.
//
// Held in currency rather than points so the weekly cost stays fixed if the
// point value is retuned — 2,000 points at ₹0.10, or 200 at ₹1, is ₹200 either
// way.
const TOP_REWARD_INR = 200;

// Rank weighting: rank 1 earns much more than rank 20 even for similar area, so
// finishing first is worth chasing. Weight for rank r (1-based) is 1/r^0.8,
// which decays fast at the top and flattens out lower down.
function rankWeight(rank) {
  return 1 / Math.pow(rank, 0.8);
}

/// Splits the rewards across the ranked holders.
///
/// `holders` — [{ userId, userName, area }], any order.
/// `pointValueInr` — the configured rupee value of one point, used to convert
/// the top award into points.
///
/// Rank 1 always receives exactly [TOP_REWARD_INR]; the rest are scaled down by
/// rank and by how much land they hold relative to the leader. Returns
/// [{ userId, userName, area, rank, points }] for the paid places only, highest
/// first. Pure, so the split is unit-testable without a database.
function computeSeasonRewards(
  holders,
  { topN = TOP_N, topRewardInr = TOP_REWARD_INR, pointValueInr = 0.1 } = {},
) {
  const ranked = holders
    .filter((h) => Number(h.area) > 0)
    .sort((a, b) => Number(b.area) - Number(a.area))
    .slice(0, topN)
    .map((h, i) => ({ ...h, rank: i + 1 }));

  if (!ranked.length) return [];

  const totalArea = ranked.reduce((sum, h) => sum + Number(h.area), 0);
  if (!(totalArea > 0)) return [];

  const value = Number(pointValueInr) > 0 ? Number(pointValueInr) : 0.1;
  const topPoints = Math.max(1, Math.round(Number(topRewardInr) / value));

  // Each place's score blends its rank weight with its share of the land held,
  // so a runner who holds far more ground is rewarded for it, while rank still
  // dominates at the top of the table.
  const scored = ranked.map((h) => ({
    ...h,
    score: rankWeight(h.rank) * (0.5 + 0.5 * (Number(h.area) / totalArea)),
  }));
  const topScore = scored[0].score;

  return scored
    .map((h) => ({
      userId: h.userId,
      userName: h.userName,
      area: Number(h.area),
      rank: h.rank,
      // Relative to the leader, so rank 1 lands on exactly the top award.
      points: Math.max(1, Math.round(topPoints * (h.score / topScore))),
    }))
    .sort((a, b) => a.rank - b.rank);
}

/// Pays out a finished season. Idempotent per user per season via the ledger's
/// unique `idempotencyKey`, so re-running it (a retried cron, two instances
/// racing) cannot double-pay.
///
/// Returns { season, paid, totalPoints, alreadySettled, results }.
async function settleSeason(season) {
  const territories = await Territory.find({ season, area: { $gt: 0 } }).lean();
  const { notifyUser } = require('./fcm');
  // Prize and rate as configured when the season is settled.
  const { readPointsConfig } = require('./routes/config');
  const { pointValueInr, seasonTopRewardInr } = await readPointsConfig();
  const rewards = computeSeasonRewards(
    territories.map((t) => ({
      userId: t.userId,
      userName: t.userName || 'Runner',
      area: t.area,
    })),
    { pointValueInr, topRewardInr: seasonTopRewardInr },
  );

  const results = [];
  let paid = 0;
  let totalPoints = 0;
  let alreadySettled = 0;

  for (const r of rewards) {
    const idempotencyKey = `season_${season}_${String(r.userId)}`;
    const existing = await WalletTransaction.findOne({ idempotencyKey }).lean();
    if (existing) {
      alreadySettled += 1;
      results.push({ ...r, userId: String(r.userId), skipped: 'already settled' });
      continue;
    }

    try {
      const updated = await User.findByIdAndUpdate(
        r.userId,
        { $inc: { walletBalance: r.points } },
        { new: true },
      );
      await WalletTransaction.create({
        userId: r.userId,
        type: 'credit',
        amount: r.points,
        balanceAfter: updated ? updated.walletBalance || 0 : r.points,
        source: 'season_reward',
        sourceId: season,
        idempotencyKey,
        description: `Season ${season} — rank #${r.rank} (${(r.area / 1e6).toFixed(2)} km² held)`,
      });
      // Tell them they won — a silent payout is indistinguishable from no
      // payout, and this is the moment the whole weekly contest pays off.
      notifyUser(r.userId, {
        title:
          r.rank === 1
            ? `You won the week! #${r.rank}`
            : `You finished #${r.rank} this week`,
        body: `${r.points.toLocaleString()} points for ${(r.area / 1e6).toFixed(2)} km² held. Season ${season}.`,
        data: {
          type: 'season',
          season,
          rank: r.rank,
          points: r.points,
        },
      });

      paid += 1;
      totalPoints += r.points;
      results.push({ ...r, userId: String(r.userId) });
    } catch (e) {
      // A duplicate key here means a concurrent settle already paid this user.
      if (e && e.code === 11000) {
        alreadySettled += 1;
        results.push({ ...r, userId: String(r.userId), skipped: 'already settled' });
        continue;
      }
      throw e;
    }
  }

  // Record that the season was settled, so the "settle what's due" path knows
  // not to look at it again even if nobody qualified for a payout.
  await coll('season_settlements').updateOne(
    { season },
    { $set: { season, settledAt: new Date(), paid, totalPoints } },
    { upsert: true },
  );

  return { season, paid, totalPoints, alreadySettled, results };
}

/// True when the given season has already been settled.
async function isSettled(season) {
  const doc = await coll('season_settlements').findOne({ season });
  return !!doc;
}

module.exports = {
  computeSeasonRewards,
  settleSeason,
  isSettled,
  TOP_N,
  TOP_REWARD_INR,
};
