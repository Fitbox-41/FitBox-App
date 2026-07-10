import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

import '../data/mock_data.dart';
import '../data/models/fitness_stats.dart';
import 'secure_storage.dart';

/// Reads real fitness data on mobile from the device step sensor (`pedometer`),
/// deriving distance and calories. On web / unsupported platforms it falls back
/// to sample data (there is no step sensor in a browser).
class FitnessService {
  FitnessService(this._storage);

  final SecureStorage _storage;

  // Rough conversions for step-derived metrics.
  static const double _strideMetres = 0.762; // avg stride
  static const double _kcalPerStep = 0.04;
  static const int _stepGoal = 10000;

  bool get _isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Stream<FitnessStats> watch() async* {
    if (!_isMobile) {
      // No sensors in the browser — show illustrative sample data.
      yield MockData.fitnessStats;
      return;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      final PermissionStatus status =
          await Permission.activityRecognition.request();
      if (!status.isGranted) {
        yield _statsFor(0);
        return;
      }
    }

    yield _statsFor(0);
    yield* Pedometer.stepCountStream.asyncMap((StepCount event) async {
      final int today = await _todayFromCumulative(event.steps);
      return _statsFor(today);
    });
  }

  /// The sensor reports cumulative steps since boot. Convert to "today" using a
  /// persisted daily baseline (resets each calendar day and on reboot).
  Future<int> _todayFromCumulative(int cumulative) async {
    final DateTime now = DateTime.now();
    final String todayKey = '${now.year}-${now.month}-${now.day}';
    final String? storedDate = await _storage.read('steps_date');
    final int? storedBaseline =
        int.tryParse(await _storage.read('steps_baseline') ?? '');

    if (storedDate != todayKey ||
        storedBaseline == null ||
        cumulative < storedBaseline) {
      await _storage.write('steps_date', todayKey);
      await _storage.write('steps_baseline', cumulative.toString());
      return 0;
    }
    return cumulative - storedBaseline;
  }

  FitnessStats _statsFor(int steps) {
    final double km = steps * _strideMetres / 1000;
    return FitnessStats(
      steps: steps,
      stepGoal: _stepGoal,
      distanceKm: km,
      caloriesKcal: (steps * _kcalPerStep).round(),
      activeMinutes: (steps / 100).round(), // rough: ~100 steps/active minute
      weeklySteps: MockData.fitnessStats.weeklySteps, // history needs Health APIs
    );
  }
}

final fitnessServiceProvider =
    Provider<FitnessService>((ref) => FitnessService(ref.watch(secureStorageProvider)));
