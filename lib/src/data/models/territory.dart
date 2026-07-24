import 'geo_point.dart';

/// One polygon of a territory: an outer ring plus any holes (a hole appears when
/// another runner has carved a piece out of the middle of your land).
class TerritoryPolygon {
  const TerritoryPolygon(this.outer, this.holes);
  final List<GeoPoint> outer;
  final List<List<GeoPoint>> holes;
}

/// A user's current territory on the shared map — one or more polygons + the
/// total area they hold. Parsed from the backend's GeoJSON Polygon/MultiPolygon.
class TerritoryArea {
  const TerritoryArea({
    required this.userId,
    required this.userName,
    required this.area,
    required this.polygons,
  });

  final String userId;
  final String userName;
  final double area; // square metres
  final List<TerritoryPolygon> polygons;

  double get areaKm2 => area / 1000000;

  factory TerritoryArea.fromJson(Map<String, dynamic> j) => TerritoryArea(
        userId: (j['userId'] ?? '').toString(),
        userName: (j['userName'] ?? 'Runner').toString(),
        area: (j['area'] as num?)?.toDouble() ?? 0,
        polygons: _parseGeometry(j['geometry']),
      );

  // GeoJSON is [lng, lat] → GeoPoint(lat, lng).
  static List<GeoPoint> _ring(List<dynamic> ring) => ring
      .map((dynamic c) => GeoPoint(
            ((c as List<dynamic>)[1] as num).toDouble(),
            (c[0] as num).toDouble(),
          ))
      .toList();

  static TerritoryPolygon _poly(List<dynamic> rings) => TerritoryPolygon(
        _ring(rings.first as List<dynamic>),
        rings.skip(1).map((dynamic r) => _ring(r as List<dynamic>)).toList(),
      );

  static List<TerritoryPolygon> _parseGeometry(dynamic geom) {
    if (geom is! Map) return const <TerritoryPolygon>[];
    final Object? coords = geom['coordinates'];
    if (coords is! List) return const <TerritoryPolygon>[];
    switch (geom['type']) {
      case 'Polygon':
        return <TerritoryPolygon>[_poly(coords)];
      case 'MultiPolygon':
        return coords
            .map((dynamic p) => _poly(p as List<dynamic>))
            .toList();
      default:
        return const <TerritoryPolygon>[];
    }
  }
}
