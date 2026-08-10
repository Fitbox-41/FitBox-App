// Weekly season payout rules — run with `node --test`.
//
// These pin down who gets paid and roughly how much, because the split decides
// real redeemable value and is easy to break silently.

const test = require('node:test');
const assert = require('node:assert');
const { computeSeasonRewards, TOP_N, SEASON_POOL_POINTS } = require('../seasonRewards');

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

test('holding more land earns more at the same table size', () => {
  const even = computeSeasonRewards(holders([50000, 50000]));
  const skewed = computeSeasonRewards(holders([90000, 10000]));
  assert.ok(
    skewed[0].points > even[0].points,
    'a dominant leader should out-earn a leader in a tight race',
  );
});

test('the pot is shared, not multiplied', () => {
  const rewards = computeSeasonRewards(holders([90000, 80000, 70000]));
  const total = rewards.reduce((sum, r) => sum + r.points, 0);
  // Rounding to whole points moves the total slightly either way.
  assert.ok(Math.abs(total - SEASON_POOL_POINTS) <= rewards.length,
    `expected ~${SEASON_POOL_POINTS}, got ${total}`);
});

test('a lone holder takes the whole pot', () => {
  const rewards = computeSeasonRewards(holders([12345]));
  assert.strictEqual(rewards.length, 1);
  assert.strictEqual(rewards[0].points, SEASON_POOL_POINTS);
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
