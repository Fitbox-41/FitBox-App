import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';
import 'models/run_activity.dart';
import 'models/run_result.dart';

/// Reads the user's runs from the app backend (`GET /api/runs`).
class RunsRepository {
  RunsRepository(this._dio);

  final Dio _dio;

  Future<List<RunActivity>> fetch() async {
    final res = await _dio.get('/runs');
    final map = Map<String, dynamic>.from(res.data as Map);
    final list = (map['runs'] as List?) ?? const [];
    return list
        .map((e) => RunActivity.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Persists an in-app recorded run to the backend (`POST /api/runs`).
  ///
  /// The same call claims the territory the route covered and credits the
  /// distance reward, so the result carries both back for the summary screen.
  /// Re-sending a run the server already has is a no-op there (matched on
  /// `clientId`), which makes retrying a failed upload safe.
  Future<RunSyncResult> save(RunActivity run) async {
    final res = await _dio.post('/runs', data: run.toBackendJson());
    final map = Map<String, dynamic>.from(res.data as Map);
    return RunSyncResult(
      claimedAreaSqm: (map['claimedAreaSqm'] as num?)?.toDouble() ?? 0,
      pointsAwarded: (map['pointsAwarded'] as num?)?.toInt() ?? 0,
      territoryMessage: map['territoryMessage'] as String?,
    );
  }
}

final runsRepositoryProvider = Provider<RunsRepository>(
  (ref) => RunsRepository(ref.watch(appDioProvider)),
);
