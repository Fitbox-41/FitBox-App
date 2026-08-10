import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';

/// The points economy as configured in the admin portal.
///
/// The value and redemption limit are **not** compiled into the app: an admin
/// can change them and every screen (and the T&C wording) follows on the next
/// launch, with no store update. [fallback] is used only until the first
/// successful fetch, or when offline.
class PointsConfig {
  const PointsConfig({
    required this.pointValueInr,
    required this.redeemCapPercent,
    required this.terms,
  });

  final double pointValueInr;
  final double redeemCapPercent;

  /// T&C clauses, written server-side so the published wording always matches
  /// the configured numbers.
  final List<String> terms;

  /// Used before the first fetch and when offline. Kept in step with the
  /// backend defaults in `backend/routes/config.js`.
  static const PointsConfig fallback = PointsConfig(
    pointValueInr: 0.1,
    redeemCapPercent: 10,
    terms: <String>[
      'FitBox Points are a promotional reward with no cash value. They cannot be transferred, sold, or withdrawn as cash.',
      'Each point has a redemption value of ₹0.10 when applied to an eligible order.',
      "Points may be redeemed for a discount of up to 10% of an order's value. The remaining balance must be paid using a standard payment method.",
      'Points are awarded as a weekly competition, not per activity. Each season runs Monday to Monday (UTC); when it closes, players are ranked by the territory they hold and only the top 20 receive points.',
      'FitBox may adjust, expire, or revoke points in case of error, abuse, or fraud.',
      'These terms may change; continued use of FitBox constitutes acceptance.',
    ],
  );

  /// "₹0.10"
  String get formattedValue => '₹${pointValueInr.toStringAsFixed(2)}';

  factory PointsConfig.fromJson(Map<String, dynamic> json) => PointsConfig(
        pointValueInr:
            (json['pointValueInr'] as num?)?.toDouble() ?? fallback.pointValueInr,
        redeemCapPercent: (json['redeemCapPercent'] as num?)?.toDouble() ??
            fallback.redeemCapPercent,
        terms: (json['terms'] as List<dynamic>?)
                ?.map((dynamic e) => e.toString())
                .toList() ??
            fallback.terms,
      );
}

class PointsConfigRepository {
  PointsConfigRepository(this._dio);

  final Dio _dio;

  Future<PointsConfig> fetch() async {
    final Response<dynamic> res = await _dio.get<dynamic>('/config/points');
    return PointsConfig.fromJson(Map<String, dynamic>.from(res.data as Map));
  }
}

final pointsConfigRepositoryProvider = Provider<PointsConfigRepository>(
  (ref) => PointsConfigRepository(ref.watch(appDioProvider)),
);

/// The live points config, falling back to [PointsConfig.fallback] rather than
/// erroring — a config lookup must never stop the wallet from rendering.
final pointsConfigProvider = FutureProvider<PointsConfig>((ref) async {
  try {
    return await ref.watch(pointsConfigRepositoryProvider).fetch();
  } catch (_) {
    return PointsConfig.fallback;
  }
});
