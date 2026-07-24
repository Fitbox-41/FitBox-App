// Territory land-grab geometry (contested area capture).
//
// A run loop encloses an area → the capturer claims that whole polygon. Any
// overlap with other users' existing territory is TAKEN from them (subtracted)
// and effectively transferred to the capturer (whose claim includes it). Pure
// functions over GeoJSON geometries so they're unit-testable without a DB.
//
// Coordinate order is GeoJSON: [lng, lat].

const turf = require('@turf/turf');

const MIN_AREA_SQM = 200; // ignore tiny/degenerate loops

/// Closes a run route into a polygon Feature. `coords` = [[lng,lat], ...].
/// Returns null if it can't form a sane area.
function routeToPolygon(coords) {
  if (!Array.isArray(coords) || coords.length < 3) return null;
  const ring = coords.map((c) => [Number(c[0]), Number(c[1])]);
  // Close the ring.
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
  // Self-intersecting routes can make invalid polygons — buffer(0) cleans many.
  try {
    if (turf.kinks(poly).features.length > 0) {
      const fixed = turf.buffer(poly, 0, { units: 'meters' });
      if (fixed && fixed.geometry) poly = fixed;
    }
  } catch (_) {/* keep raw poly */}
  const area = turf.area(poly);
  if (!area || area < MIN_AREA_SQM) return null;
  return poly;
}

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

module.exports = { routeToPolygon, applyCapture, areaOf, MIN_AREA_SQM };
