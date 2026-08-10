// Weekly season payout rules — run with `node --test`.
//
// These pin down who gets paid and roughly how much, because the split decides
// real redeemable value and is easy to break silently.

const test = require('node:test');
const assert = require('node:assert');
const { computeSeasonRewards, TOP_N, TOP_REWARD_INR } = require('../seasonRewards');

const holders = (areas) =>
  areas.map((area, i) => ({ userId: `u${i}`, userName: `Runner ${i}`, area }));

test('only the top 20 are paid', () => {
  const rewards = computeSeasonRewards(holders(
    Array.from({ length: 30 }, (_, i) => 100000 - i * 1000),
  ));
  assert.strictEqual(rewards.length, TOP_N);
  assert.strictEqual(rewards[0].rank, 1);
  assert.strictEqual(rewards[TOP_N - 1].rank, TOP_N);
});

test('rank 1 earns the most and awards decrease down the table', () => {
  const rewards = computeSeasonRewards(holders([90000, 80000, 70000, 60000, 50000]));
  for (let i = 1; i < rewards.length; i++) {
    assert.ok(
      rewards[i].points <= rewards[i - 1].points,
      `rank ${i + 1} (${rewards[i].points}) must not beat rank ${i} (${rewards[i - 1].points})`,
    );
  }
  assert.ok(rewards[0].points > rewards[rewards.length - 1].points);
});

test('below first place, holding more land earns more', () => {
  // First place is a fixed award, so the area weighting shows up in the chasers:
  // a runner-up who is neck-and-neck earns more than one who was crushed.
  const close = computeSeasonRewards(holders([50000, 50000]), { pointValueInr: 0.1 });
  const crushed = computeSeasonRewards(holders([90000, 10000]), { pointValueInr: 0.1 });
  assert.strictEqual(close[0].points, crushed[0].points, 'first place is fixed');
  assert.ok(
    close[1].points > crushed[1].points,
    `a close runner-up (${close[1].points}) should out-earn a distant one (${crushed[1].points})`,
  );
});

test('rank 1 is worth exactly the top award, whatever a point is worth', () => {
  // ₹200 at ₹0.10/point = 2,000 points.
  const atTenPaise = computeSeasonRewards(holders([90000, 50000, 10000]), { pointValueInr: 0.1 });
  assert.strictEqual(atTenPaise[0].points, TOP_REWARD_INR / 0.1);

  // Retuning the point value must not change what first place costs in rupees.
  const atOneRupee = computeSeasonRewards(holders([90000, 50000, 10000]), { pointValueInr: 1 });
  assert.strictEqual(atOneRupee[0].points, TOP_REWARD_INR / 1);
  assert.strictEqual(atOneRupee[0].points * 1, atTenPaise[0].points * 0.1);
});

test('rank 1 gets the top award regardless of how close the race is', () => {
  const runaway = computeSeasonRewards(holders([900000, 1000]), { pointValueInr: 0.1 });
  const tight = computeSeasonRewards(holders([50000, 49999]), { pointValueInr: 0.1 });
  assert.strictEqual(runaway[0].points, 2000);
  assert.strictEqual(tight[0].points, 2000);
});

test('a full table costs a bounded amount per season', () => {
  // Worst case for cost: 20 paid places all holding the same area.
  const rewards = computeSeasonRewards(
    holders(Array.from({ length: 20 }, () => 50000)),
    { pointValueInr: 0.1 },
  );
  const totalPoints = rewards.reduce((sum, r) => sum + r.points, 0);
  const totalInr = totalPoints * 0.1;
  assert.ok(totalInr <= 1000,
    `a full season should cost at most ~₹1000, got ₹${totalInr.toFixed(2)}`);
  assert.ok(totalInr > TOP_REWARD_INR,
    'paying 20 places must cost more than paying only the winner');
});

test('a lone holder takes only the top award', () => {
  const rewards = computeSeasonRewards(holders([12345]), { pointValueInr: 0.1 });
  assert.strictEqual(rewards.length, 1);
  assert.strictEqual(rewards[0].points, 2000);
});

test('holders with no land are not paid', () => {
  const rewards = computeSeasonRewards(holders([50000, 0, 0]));
  assert.strictEqual(rewards.length, 1);
  assert.strictEqual(rewards[0].userId, 'u0');
});

test('an empty season pays nobody', () => {
  assert.deepStrictEqual(computeSeasonRewards([]), []);
  assert.deepStrictEqual(computeSeasonRewards(holders([0, 0])), []);
});

test('every paid place gets at least one point', () => {
  // A long tail of tiny holdings must not round anyone down to zero.
  const rewards = computeSeasonRewards(holders(
    [1000000, ...Array.from({ length: 19 }, () => 1)],
  ));
  assert.strictEqual(rewards.length, 20);
  for (const r of rewards) assert.ok(r.points >= 1, `rank ${r.rank} got ${r.points}`);
});

test('ranking is by area regardless of input order', () => {
  const rewards = computeSeasonRewards(holders([10000, 90000, 50000]));
  assert.deepStrictEqual(rewards.map((r) => r.userId), ['u1', 'u2', 'u0']);
});
