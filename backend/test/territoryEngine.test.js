// Territory claim rules — run with `node --test` from backend/.
//
// These guard the game's core promise: every run that covers ground takes land,
// separate areas accumulate instead of replacing each other, and standing still
// takes nothing.

const test = require('node:test');
const assert = require('node:assert');
const { routeToClaim, applyCapture, areaOf, CLAIM_RADIUS_M } = require('../territoryEngine');

const M = 1 / 111320; // ~1 metre in degrees

// Deterministic jitter so the tests never flake.
let seed = 7;
const rnd = () => ((seed = (seed * 1103515245 + 12345) % 2147483648) / 2147483648 - 0.5);
const jit = (m) => rnd() * m * M;

function outAndBack(lat, lng, metres, step = 10) {
  const n = Math.round(metres / step);
  const pts = [];
  for (let i = 0; i <= n; i++) pts.push([lng + i * step * M + jit(4), lat + jit(4)]);
  for (let i = n; i >= 0; i--) pts.push([lng + i * step * M + jit(4), lat + jit(4)]);
  return pts;
}

function loop(lat, lng, side, step = 10) {
  const n = Math.round(side / step);
  const pts = [];
  for (let i = 0; i < n; i++) pts.push([lng + i * step * M, lat]);
  for (let i = 0; i < n; i++) pts.push([lng + side * M, lat + i * step * M]);
  for (let i = 0; i < n; i++) pts.push([lng + (side - i * step) * M, lat + side * M]);
  for (let i = 0; i < n; i++) pts.push([lng, lat + (side - i * step) * M]);
  return pts;
}

test('an out-and-back run claims a corridor, not a sliver', () => {
  const claim = routeToClaim(outAndBack(28.60, 77.20, 2500));
  assert.ok(claim, 'a 5 km out-and-back must claim something');
  const area = areaOf(claim.geometry);
  // ~2.5 km of road at 2 x CLAIM_RADIUS_M wide, minus overlap on the way back.
  assert.ok(area > 80000, `expected a real corridor, got ${Math.round(area)} m²`);
});

test('a closed loop claims far more than the same distance out-and-back', () => {
  const loopArea = areaOf(routeToClaim(loop(28.60, 77.20, 1250)).geometry);
  const backArea = areaOf(routeToClaim(outAndBack(28.60, 77.20, 2500)).geometry);
  assert.ok(loopArea > backArea * 5,
    `looping must stay the winning strategy (loop ${Math.round(loopArea)} vs ${Math.round(backArea)})`);
});

test('standing still claims nothing', () => {
  const jitterOnly = Array.from({ length: 200 }, () => [77.20 + jit(3), 28.60 + jit(3)]);
  assert.strictEqual(routeToClaim(jitterOnly), null);
});

test('degenerate routes are rejected', () => {
  assert.strictEqual(routeToClaim([]), null);
  assert.strictEqual(routeToClaim([[77.2, 28.6]]), null);
  assert.strictEqual(routeToClaim(null), null);
  assert.strictEqual(routeToClaim([['x', 'y'], [null, 1]]), null);
});

test('runs in different areas accumulate instead of replacing', () => {
  let mine = null;
  let previous = 0;
  const routes = [
    outAndBack(28.60, 77.20, 2500),
    outAndBack(28.65, 77.26, 2500), // several km away
    loop(28.70, 77.30, 400),
  ];
  for (const r of routes) {
    const claim = routeToClaim(r);
    assert.ok(claim);
    const res = applyCapture(mine, [], claim);
    assert.ok(res.capturerArea > previous, 'each run must grow the total');
    previous = res.capturerArea;
    mine = res.capturerGeometry;
  }
  assert.strictEqual(mine.type, 'MultiPolygon');
  assert.strictEqual(mine.coordinates.length, 3, 'three separate holdings');
});

test('re-running the same ground does not inflate the total', () => {
  const claim = routeToClaim(loop(28.60, 77.20, 500));
  const first = applyCapture(null, [], claim);
  const second = applyCapture(first.capturerGeometry, [], claim);
  assert.ok(Math.abs(second.capturerArea - first.capturerArea) < 1,
    'claiming identical land twice must not double the area');
});

test('a rival running through your land takes it from you', () => {
  const mine = applyCapture(null, [], routeToClaim(loop(28.60, 77.20, 600))).capturerGeometry;
  const before = areaOf(mine);
  const rival = routeToClaim(loop(28.6005, 77.2005, 300));
  const res = applyCapture(null, [{ id: 'victim', geometry: mine }], rival);
  assert.strictEqual(res.updatedOthers.length, 1);
  assert.ok(res.updatedOthers[0].area < before, 'the defender must lose ground');
});

test('claim radius is the documented width', () => {
  assert.strictEqual(CLAIM_RADIUS_M, 25);
});
