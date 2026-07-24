import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';
import 'models/geo_point.dart';
import 'models/territory.dart';

/// Talks to the app backend's territory endpoints (`/api/territories`).
class TerritoryRepository {
  TerritoryRepository(this._dio);

  final Dio _dio;

  /// Every user's current territory, for the shared map.
  Future<List<TerritoryArea>> fetchAll() async {
    final Response<dynamic> res = await _dio.get<dynamic>('/territories');
    final Map<dynamic, dynamic> data = res.data as Map<dynamic, dynamic>;
    final List<dynamic> list =
        (data['territories'] as List<dynamic>?) ?? <dynamic>[];
    return list
        .map((dynamic e) =>
            TerritoryArea.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Claims the area enclosed by a finished run loop. Returns the caller's new
  /// total area (sqm), or null if the loop was too small to claim.
  Future<double?> capture(List<GeoPoint> route) async {
    // Backend expects GeoJSON order: [lng, lat].
    final List<List<double>> coords =
        route.map((GeoPoint g) => <double>[g.lng, g.lat]).toList();
    final Response<dynamic> res = await _dio.post<dynamic>(
      '/territories/capture',
      data: <String, dynamic>{'route': coords},
    );
    final Map<dynamic, dynamic> data = res.data as Map<dynamic, dynamic>;
    return (data['area'] as num?)?.toDouble();
  }
}

final territoryRepositoryProvider = Provider<TerritoryRepository>(
  (ref) => TerritoryRepository(ref.watch(appDioProvider)),
);

/// All users' territories for the shared Territory map.
final territoriesProvider = FutureProvider<List<TerritoryArea>>(
  (ref) async => ref.watch(territoryRepositoryProvider).fetchAll(),
);
