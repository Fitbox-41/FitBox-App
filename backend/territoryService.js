// Applying a territory claim to the database.
//
// Shared by POST /api/runs (every saved run claims land server-side, so a
// dropped client call can't silently lose it) and POST /api/territories/capture
// (kept for older app builds and for re-claiming an existing run). Both paths
// must behave identically, which is why this lives in one place.

const Territory = require('./models/Territory');
const SeasonProgress = require('./models/SeasonProgress');
const User = require('./models/User');
const { routeToClaim, applyCapture, areaOf, mergeGeometry } = require('./territoryEngine');
const { notifyUser } = require('./fcm');

// ISO year-week, e.g. "2026-W31" — the current weekly territory season.
function currentSeason(now = new Date()) {
  const date = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
  const dayNum = (date.getUTCDay() + 6) % 7; // Mon=0..Sun=6
  date.setUTCDate(date.getUTCDate() - dayNum + 3); // nearest Thursday
  const firstThursday = date.getTime();
  date.setUTCMonth(0, 1);
  if (date.getUTCDay() !== 4) {
    date.setUTCMonth(0, 1 + ((4 - date.getUTCDay()) + 7) % 7);
  }
  const week = 1 + Math.ceil((firstThursday - date.getTime()) / 604800000);
  const year = new Date(firstThursday).getUTCFullYear();
  return `${year}-W${String(week).padStart(2, '0')}`;
}

// Next Monday 00:00 UTC — when the current season resets.
function seasonEndsAt(now = new Date()) {
  const d = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
  const daysToMon = ((8 - d.getUTCDay()) % 7) || 7; // next Monday
  d.setUTCDate(d.getUTCDate() + daysToMon);
  return d.toISOString();
}

/// Claims the land a route covers for `userId`.
///
/// Returns { ok, claimed, total, reason }:
///   ok      — whether anything was claimed
///   claimed — sqm this route covered (corridor + any enclosed loop)
///   total   — the user's new season total, sqm
///   reason  — why nothing was claimed, when ok is false
async function claimRoute(userId, route) {
  const claim = routeToClaim(route);
  if (!claim) {
    return {
      ok: false,
      claimed: 0,
      total: 0,
      reason: 'This run was too short to claim territory — cover at least 150 m.',
    };
  }

  // Lifetime holdings — no season filter. Territory persists until invaded.
  const season = currentSeason();
  const mine = await Territory.findOne({ userId });
  const others = await Territory.find({ userId: { $ne: userId } });
  const areaBefore = (mine && mine.area) || 0;

  const result = applyCapture(
    mine ? mine.geometry : null,
    others.map((o) => ({ id: o._id, geometry: o.geometry })),
    claim,
  );

  const othersById = new Map(others.map((o) => [String(o._id), o]));

  // Apply contests to other users (shrink or remove).
  for (const u of result.updatedOthers) {
    if (!u.geometry || u.area <= 0) {
      await Territory.deleteOne({ _id: u.id });
    } else {
      await Territory.updateOne(
        { _id: u.id },
        { $set: { geometry: u.geometry, area: u.area } },
      );
    }
  }

  let userName = mine && mine.userName;
  if (!userName) {
    const u = await User.findById(userId).select('name').lean();
    userName = (u && u.name) || 'Runner';
  }

  await Territory.updateOne(
    { userId },
    {
      $set: {
        geometry: result.capturerGeometry,
        area: result.capturerArea,
        userName,
      },
      $setOnInsert: { season },
    },
    { upsert: true },
  );

  // Weekly competition progress. The prize ranks on ground gained this week, so
  // that a newcomer can win it — the lifetime holding above would just hand it
  // to whoever started first, every week.
  const gained = Math.max(0, result.capturerArea - areaBefore);
  try {
    const week = await SeasonProgress.findOne({ userId, season });
    const weekGeometry = mergeGeometry(week ? week.geometry : null, claim);
    await SeasonProgress.updateOne(
      { userId, season },
      {
        $set: { userName, geometry: weekGeometry },
        $inc: { areaGainedSqm: gained },
      },
      { upsert: true },
    );
  } catch (e) {
    // Never fail a claim over leaderboard bookkeeping — the land is what matters.
    console.error('Season progress update failed:', e.message);
  }

  // Best-effort push to everyone whose land was contested by this run.
  for (const u of result.updatedOthers) {
    const victim = othersById.get(String(u.id));
    if (!victim) continue;
    const lost = !u.geometry || u.area <= 0;
    notifyUser(victim.userId, {
      title: lost ? 'Territory lost!' : 'Your territory is under attack',
      body: lost
        ? `${userName} took over your territory. Run to reclaim it!`
        : `${userName} captured part of your territory. Defend your turf!`,
      data: { type: 'territory' },
    });
  }

  return {
    ok: true,
    claimed: areaOf(claim.geometry),
    total: result.capturerArea,
    reason: null,
  };
}

module.exports = { claimRoute, currentSeason, seasonEndsAt };
