import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';
import 'models/run_activity.dart';

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
  Future<void> save(RunActivity run) async {
    await _dio.post('/runs', data: run.toBackendJson());
  }
}

final runsRepositoryProvider = Provider<RunsRepository>(
  (ref) => RunsRepository(ref.watch(appDioProvider)),
);
