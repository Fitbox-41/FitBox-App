import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';
import 'models/challenge.dart';

/// Talks to the app backend's challenge endpoints (`/api/challenges`).
class ChallengeRepository {
  ChallengeRepository(this._dio);

  final Dio _dio;

  Future<List<Challenge>> fetchAll() async {
    final Response<dynamic> res = await _dio.get<dynamic>('/challenges');
    final Map<dynamic, dynamic> data = res.data as Map<dynamic, dynamic>;
    final List<dynamic> list =
        (data['challenges'] as List<dynamic>?) ?? <dynamic>[];
    return list
        .map((dynamic e) =>
            Challenge.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> join(String id) async {
    await _dio.post<dynamic>('/challenges/$id/join');
  }

  /// Claims the reward; returns points awarded (0 if none).
  Future<int> claim(String id) async {
    final Response<dynamic> res =
        await _dio.post<dynamic>('/challenges/$id/claim');
    final Map<dynamic, dynamic> data = res.data as Map<dynamic, dynamic>;
    return (data['awarded'] as num?)?.toInt() ?? 0;
  }
}

final challengeRepositoryProvider = Provider<ChallengeRepository>(
  (ref) => ChallengeRepository(ref.watch(appDioProvider)),
);

final challengesProvider = FutureProvider<List<Challenge>>(
  (ref) async => ref.watch(challengeRepositoryProvider).fetchAll(),
);
