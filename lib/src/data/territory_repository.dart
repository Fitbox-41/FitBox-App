import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../presentation/auth/auth_controller.dart';
import '../services/api_client.dart';
import 'models/geo_point.dart';
import 'models/territory.dart';

/// Which slice of the map to show.
///
/// Territory itself is permanent — it is a record of everywhere you've run and
/// only shrinks when a rival takes it. The weekly view exists because the prize
/// is decided on the ground you claim within a season, so a player needs to see
/// that separately from their lifetime holding.
enum TerritoryView { lifetime, week }

/// The shared map plus the current weekly-season context. The countdown is to
/// the weekly *prize*, not to a reset — nothing is wiped when a season ends.
class TerritorySnapshot {
  const TerritorySnapshot({
    required this.areas,
    this.season,
    this.seasonEndsAt,
    this.view = TerritoryView.lifetime,
  });

  final List<TerritoryArea> areas;
  final String? season; // ISO year-week, e.g. "2026-W31"
  final DateTime? seasonEndsAt; // when the current season's prize is decided
  final TerritoryView view;
}

/// Talks to the app backend's territory endpoints (`/api/territories`).
class TerritoryRepository {
  TerritoryRepository(this._dio);

  final Dio _dio;

  /// Every user's territory, plus the season context.
  ///
  /// [view] picks the lifetime map (everything still held) or just what has been
  /// claimed during the current season.
  Future<TerritorySnapshot> fetchAll({
    TerritoryView view = TerritoryView.lifetime,
  }) async {
    final Response<dynamic> res = await _dio.get<dynamic>(
      '/territories',
      queryParameters: view == TerritoryView.week
          ? <String, dynamic>{'view': 'week'}
          : null,
    );
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
      view: data['view'] == 'week' ? TerritoryView.week : TerritoryView.lifetime,
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

/// Which slice of the map the Territory screen is showing. Lifetime by default —
/// the permanent record is the point of the feature.
class TerritoryViewController extends Notifier<TerritoryView> {
  @override
  TerritoryView build() => TerritoryView.lifetime;

  void show(TerritoryView view) => state = view;
}

final territoryViewProvider =
    NotifierProvider<TerritoryViewController, TerritoryView>(
        TerritoryViewController.new);

/// All users' territories for the shared Territory map, plus season context.
///
/// Keyed on the signed-in user: the map highlights "yours" by user id, so a
/// cached snapshot from a previous account would paint their land as this
/// account's. Also keyed on the selected view, so switching tabs refetches.
final territoriesProvider = FutureProvider<TerritorySnapshot>((ref) async {
  ref.watch(authControllerProvider.select((AuthState s) => s.user?.id));
  final TerritoryView view = ref.watch(territoryViewProvider);
  return ref.watch(territoryRepositoryProvider).fetchAll(view: view);
});

/// The weekly competition standings — always the week view, regardless of what
/// the map is currently showing.
///
/// Separate from [territoriesProvider] on purpose: the leaderboard decides the
/// prize, so it must always rank the week's claims even while the map is set to
/// the lifetime view.
final weeklyStandingsProvider = FutureProvider<TerritorySnapshot>((ref) async {
  ref.watch(authControllerProvider.select((AuthState s) => s.user?.id));
  return ref
      .watch(territoryRepositoryProvider)
      .fetchAll(view: TerritoryView.week);
});
