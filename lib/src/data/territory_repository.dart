import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../presentation/auth/auth_controller.dart';
import '../services/api_client.dart';
import 'models/geo_point.dart';
import 'models/territory.dart';

/// The shared map plus the current weekly-season context (territory resets each
/// Monday, so the app shows a countdown to the reset).
class TerritorySnapshot {
  const TerritorySnapshot({
    required this.areas,
    this.season,
    this.seasonEndsAt,
  });

  final List<TerritoryArea> areas;
  final String? season; // ISO year-week, e.g. "2026-W31"
  final DateTime? seasonEndsAt; // when the current season resets (UTC)
}

/// Talks to the app backend's territory endpoints (`/api/territories`).
class TerritoryRepository {
  TerritoryRepository(this._dio);

  final Dio _dio;

  /// Every user's current-season territory, plus the season/countdown.
  Future<TerritorySnapshot> fetchAll() async {
    final Response<dynamic> res = await _dio.get<dynamic>('/territories');
    final Map<dynamic, dynamic> data = res.data as Map<dynamic, dynamic>;
    final List<dynamic> list =
        (data['territories'] as List<dynamic>?) ?? <dynamic>[];
    return TerritorySnapshot(
      areas: list
          .map((dynamic e) =>
              TerritoryArea.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      season: data['season'] as String?,
      seasonEndsAt:
          DateTime.tryParse((data['seasonEndsAt'] as String?) ?? '')?.toLocal(),
    );
  }

  /// Claims the area enclosed by a finished run loop. Returns the area claimed
  /// by this run and the caller's new total (both sqm).
  Future<({double claimed, double total})> capture(List<GeoPoint> route) async {
    // Backend expects GeoJSON order: [lng, lat].
    final List<List<double>> coords =
        route.map((GeoPoint g) => <double>[g.lng, g.lat]).toList();
    final Response<dynamic> res = await _dio.post<dynamic>(
      '/territories/capture',
      data: <String, dynamic>{'route': coords},
    );
    final Map<dynamic, dynamic> data = res.data as Map<dynamic, dynamic>;
    return (
      claimed: (data['claimed'] as num?)?.toDouble() ?? 0,
      total: (data['area'] as num?)?.toDouble() ?? 0,
    );
  }
}

final territoryRepositoryProvider = Provider<TerritoryRepository>(
  (ref) => TerritoryRepository(ref.watch(appDioProvider)),
);

/// All users' territories for the shared Territory map, plus season context.
///
/// Keyed on the signed-in user: the map highlights "yours" by user id, so a
/// cached snapshot from a previous account would paint their land as this
/// account's.
final territoriesProvider = FutureProvider<TerritorySnapshot>((ref) async {
  ref.watch(authControllerProvider.select((AuthState s) => s.user?.id));
  return ref.watch(territoryRepositoryProvider).fetchAll();
});
