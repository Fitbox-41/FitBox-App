import 'package:health/health.dart';

import '../data/models/fitness_stats.dart';

const int _stepGoal = 10000;

/// Reads today's steps/calories/distance and a 7-day step history from
/// Health Connect (Android) / HealthKit (iOS). Returns null if unavailable or
/// permission is denied, so the caller can fall back to the pedometer.
Future<FitnessStats?> fetchHealthStats() async {
  const List<HealthDataType> types = <HealthDataType>[
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.DISTANCE_DELTA,
  ];
  final Health health = Health();
  try {
    await health.configure();
    final bool granted = await health.requestAuthorization(
      types,
      permissions:
          List<HealthDataAccess>.filled(types.length, HealthDataAccess.READ),
    );
    if (!granted) return null;

    final DateTime now = DateTime.now();
    final DateTime midnight = DateTime(now.year, now.month, now.day);

    final int steps = await health.getTotalStepsInInterval(midnight, now) ?? 0;

    double calories = 0;
    double distanceMetres = 0;
    final List<HealthDataPoint> points = await health.getHealthDataFromTypes(
      types: const <HealthDataType>[
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.DISTANCE_DELTA,
      ],
      startTime: midnight,
      endTime: now,
    );
    for (final HealthDataPoint p in points) {
      final num value =
          p.value is NumericHealthValue ? (p.value as NumericHealthValue).numericValue : 0;
      if (p.type == HealthDataType.ACTIVE_ENERGY_BURNED) {
        calories += value.toDouble();
      } else if (p.type == HealthDataType.DISTANCE_DELTA) {
        distanceMetres += value.toDouble();
      }
    }

    final List<int> weekly = <int>[];
    for (int i = 6; i >= 0; i--) {
      final DateTime dayStart = midnight.subtract(Duration(days: i));
      final DateTime dayEnd =
          i == 0 ? now : dayStart.add(const Duration(days: 1));
      weekly.add(await health.getTotalStepsInInterval(dayStart, dayEnd) ?? 0);
    }

    return FitnessStats(
      steps: steps,
      stepGoal: _stepGoal,
      distanceKm: distanceMetres / 1000,
      caloriesKcal: calories.round(),
      activeMinutes: (steps / 100).round(),
      weeklySteps: weekly,
    );
  } catch (_) {
    return null;
  }
}
