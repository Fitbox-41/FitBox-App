/// A single GPS sample on a run route (kept plugin-agnostic so the data layer
/// doesn't depend on google_maps_flutter; the map widget converts to LatLng).
class GeoPoint {
  const GeoPoint(this.lat, this.lng);

  final double lat;
  final double lng;

  Map<String, dynamic> toMap() => <String, dynamic>{'lat': lat, 'lng': lng};

  factory GeoPoint.fromMap(Map<dynamic, dynamic> m) => GeoPoint(
        (m['lat'] as num).toDouble(),
        (m['lng'] as num).toDouble(),
      );

  /// `[lat, lng]` pair — compact form for backend/local JSON.
  List<double> toPair() => <double>[lat, lng];

  factory GeoPoint.fromPair(List<dynamic> p) =>
      GeoPoint((p[0] as num).toDouble(), (p[1] as num).toDouble());
}
