// Territory land-grab geometry (contested area capture).
//
// A run claims TWO things, unioned together:
//   1. a corridor along the route itself (CLAIM_RADIUS_M each side), so every
//      run takes land in proportion to the distance covered — an out-and-back
//      along a road is a real claim, not a hairline sliver; and
//   2. the area enclosed by the route if it closes a loop, which is far larger,
//      so looping stays the winning strategy.
// Any overlap with other users' existing territory is TAKEN from them
// (subtracted) and effectively transferred to the capturer (whose claim
// includes it). Pure functions over GeoJSON geometries so they're unit-testable
// without a DB.
//
// Coordinate order is GeoJSON: [lng, lat].

const turf = require('@turf/turf');

const MIN_AREA_SQM = 200; // ignore tiny/degenerate claims
const CLAIM_RADIUS_M = 25; // half-width of the corridor claimed along a route
// A phone lying still still emits a wandering GPS trace, and buffering that
// noise would hand out land for doing nothing. Require real movement before a
// route can claim anything — this is enforced here, server-side, so it holds
// even if a client posts a route directly.
const MIN_ROUTE_METRES = 150;
// GPS traces are dense and noisy; simplifying first keeps the geometry work
// (buffer/unkink/union) fast enough for a serverless request on a long run.
const SIMPLIFY_TOLERANCE = 0.00002; // ~2 m
const MAX_POINTS = 3000;

/// Cleans a raw route into [[lng,lat], ...] — drops non-finite and repeated
/// points (a phone sitting still emits hundreds of identical samples).
function cleanCoords(coords) {
  if (!Array.isArray(coords)) return [];
  const out = [];
  for (const c of coords) {
    if (!Array.isArray(c) || c.length < 2) continue;
    const lng = Number(c[0]);
    const lat = Number(c[1]);
    if (!Number.isFinite(lng) || !Number.isFinite(lat)) continue;
    if (Math.abs(lat) > 90 || Math.abs(lng) > 180) continue;
    const prev = out[out.length - 1];
    if (prev && prev[0] === lng && prev[1] === lat) continue;
    out.push([lng, lat]);
  }
  // Cap absurdly long traces by sampling evenly — protects the request budget.
  if (out.length > MAX_POINTS) {
    const step = out.length / MAX_POINTS;
    const capped = [];
    for (let i = 0; i < MAX_POINTS; i++) capped.push(out[Math.floor(i * step)]);
    capped.push(out[out.length - 1]);
    return capped;
  }
  return out;
}

/// The corridor swept along the route — what makes every run worth land.
function corridorOf(pts) {
  if (pts.length < 2) return null;
  try {
    let line = turf.lineString(pts);
    try {
      line = turf.simplify(line, { tolerance: SIMPLIFY_TOLERANCE, highQuality: false });
    } catch (_) {/* simplify is an optimisation only */}
    const buffered = turf.buffer(line, CLAIM_RADIUS_M, { units: 'meters' });
    return buffered && buffered.geometry ? buffered : null;
  } catch (_) {
    return null;
  }
}

/// The area enclosed by the route when it forms a loop. Self-intersecting
/// traces are split into valid rings (unkink) and the pieces unioned, so a
/// figure-of-eight or a doubled-back loop still counts.
function enclosedOf(pts) {
  if (pts.length < 3) return null;
  const ring = pts.map((p) => [p[0], p[1]]);
  const first = ring[0];
  const last = ring[ring.length - 1];
  if (first[0] !== last[0] || first[1] !== last[1]) ring.push([first[0], first[1]]);
  if (ring.length < 4) return null;
  let poly;
  try {
    poly = turf.polygon([ring]);
  } catch (_) {
    return null;
  }
  try {
    if (turf.kinks(poly).features.length > 0) {
      const parts = turf.unkinkPolygon(poly).features.filter((f) => {
        try {
          return turf.area(f) >= MIN_AREA_SQM;
        } catch (_) {
          return false;
        }
      });
      if (!parts.length) return null;
      let merged = parts[0];
      for (let i = 1; i < parts.length; i++) {
        try {
          const u = turf.union(turf.featureCollection([merged, parts[i]]));
          if (u) merged = u;
        } catch (_) {/* keep what merged so far */}
      }
      poly = merged;
    }
  } catch (_) {/* fall through with the raw ring */}
  let area = 0;
  try {
    area = turf.area(poly);
  } catch (_) {
    return null;
  }
  if (!area || area < MIN_AREA_SQM) return null;
  return poly;
}

/// Turns a finished run route into the land it claims: the corridor along the
/// route unioned with any area the route encloses. `coords` = [[lng,lat], ...].
/// Returns a Feature, or null if the run is too short/degenerate to claim.
function routeToClaim(coords) {
  const pts = cleanCoords(coords);
  if (pts.length < 2) return null;

  // Reject routes that never really went anywhere (jitter while stationary).
  // Straight-line spread is checked too, so pacing back and forth in one spot
  // can't accumulate enough path length to qualify.
  try {
    const line = turf.lineString(pts);
    const metres = turf.length(line, { units: 'kilometers' }) * 1000;
    if (metres < MIN_ROUTE_METRES) return null;
    const [minX, minY, maxX, maxY] = turf.bbox(line);
    const spread = turf.distance([minX, minY], [maxX, maxY], { units: 'kilometers' }) * 1000;
    if (spread < CLAIM_RADIUS_M * 2) return null;
  } catch (_) {
    return null;
  }

  let claim = corridorOf(pts);
  const enclosed = enclosedOf(pts);
  if (enclosed) {
    if (!claim) {
      claim = enclosed;
    } else {
      try {
        const u = turf.union(turf.featureCollection([claim, enclosed]));
        if (u) claim = u;
      } catch (_) {/* corridor alone is still a valid claim */}
    }
  }
  if (!claim) return null;
  let area = 0;
  try {
    area = turf.area(claim);
  } catch (_) {
    return null;
  }
  if (!area || area < MIN_AREA_SQM) return null;
  return claim;
}

/// Back-compat alias — the loop-only name this module used to export.
const routeToPolygon = routeToClaim;

function feat(geometry) {
  return turf.feature(geometry);
}

function areaOf(geometry) {
  if (!geometry) return 0;
  try {
    return turf.area(feat(geometry));
  } catch (_) {
    return 0;
  }
}

/// geometry MINUS cutterFeature. Returns a geometry, or null if fully removed.
function subtract(geometry, cutterFeature) {
  if (!geometry) return null;
  try {
    const diff = turf.difference(turf.featureCollection([feat(geometry), cutterFeature]));
    return diff ? diff.geometry : null;
  } catch (_) {
    return geometry; // on failure, leave the owner's territory unchanged
  }
}

/// geometry UNION cutterFeature (grow the capturer's territory).
function merge(geometry, addFeature) {
  if (!geometry) return addFeature.geometry;
  try {
    const u = turf.union(turf.featureCollection([feat(geometry), addFeature]));
    return u ? u.geometry : geometry;
  } catch (_) {
    return geometry;
  }
}

/// Applies a capture. Inputs are plain GeoJSON geometries.
///   capturerGeometry: the capturer's current territory (or null)
///   others: [{ id, geometry }] every OTHER user's territory
///   newPolygon: the closed run-loop polygon Feature (from routeToPolygon)
/// Returns { capturerGeometry, capturerArea, updatedOthers: [{id, geometry|null, area}] }.
function applyCapture(capturerGeometry, others, newPolygon) {
  const updatedOthers = [];
  for (const o of others) {
    if (!o.geometry) continue;
    let intersects = false;
    try {
      intersects = turf.booleanIntersects(feat(o.geometry), newPolygon);
    } catch (_) {
      intersects = true; // be safe — attempt the subtraction
    }
    if (!intersects) continue;
    const remaining = subtract(o.geometry, newPolygon);
    updatedOthers.push({
      id: o.id,
      geometry: remaining, // null → territory fully taken, delete it
      area: areaOf(remaining),
    });
  }
  const capturerGeom = merge(capturerGeometry, newPolygon);
  return {
    capturerGeometry: capturerGeom,
    capturerArea: areaOf(capturerGeom),
    updatedOthers,
  };
}

module.exports = {
  routeToClaim,
  routeToPolygon, // legacy alias
  applyCapture,
  areaOf,
  // Exposed for the weekly-progress union, which accumulates a season's claims
  // separately from the lifetime holding.
  mergeGeometry: merge,
  MIN_AREA_SQM,
  CLAIM_RADIUS_M,
};
