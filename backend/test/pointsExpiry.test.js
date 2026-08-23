// Point expiry rules — run with `node --test`.
//
// The FIFO walk and the sweep need a database, so they're exercised against the
// real data during verification. What's covered here is the part that decides
// *when* a point dies, which is pure and easy to get subtly wrong.

const test = require('node:test');
const assert = require('node:assert');
const { creditExpiry, EXPIRY_DAYS } = require('../pointsExpiry');

const DAY = 24 * 60 * 60 * 1000;

test('the expiry window is the 99 days the T&C promises', () => {
  assert.strictEqual(EXPIRY_DAYS, 99);
});

test('a credit expires 99 days after it is earned', () => {
  const earned = new Date('2026-08-13T10:30:00.000Z');
  const expires = creditExpiry(earned);
  assert.strictEqual(expires.getTime() - earned.getTime(), 99 * DAY);
  assert.strictEqual(expires.toISOString(), '2026-11-20T10:30:00.000Z');
});

test('expiry does not drift across a month or year boundary', () => {
  // 99 days from mid-October lands in the next year — the arithmetic must not
  // assume 30-day months.
  const earned = new Date('2026-10-15T00:00:00.000Z');
  assert.strictEqual(
    creditExpiry(earned).toISOString(),
    '2027-01-22T00:00:00.000Z',
  );
});

test('expiry is computed in UTC, so it does not shift with the server timezone', () => {
  // Two instants one second either side of UTC midnight must stay 99 days apart
  // rather than snapping to a local calendar day.
  const before = new Date('2026-08-13T23:59:59.000Z');
  const after = new Date('2026-08-14T00:00:01.000Z');
  assert.strictEqual(creditExpiry(before).getTime() - before.getTime(), 99 * DAY);
  assert.strictEqual(creditExpiry(after).getTime() - after.getTime(), 99 * DAY);
});

test('the caller is never handed back the same Date object to mutate', () => {
  const earned = new Date('2026-08-13T00:00:00.000Z');
  const expires = creditExpiry(earned);
  assert.notStrictEqual(expires, earned);
  assert.strictEqual(earned.toISOString(), '2026-08-13T00:00:00.000Z');
});
