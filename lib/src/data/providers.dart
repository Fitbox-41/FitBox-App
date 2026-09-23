import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../presentation/auth/auth_controller.dart';
import 'models/fitness_stats.dart';
import 'models/run_activity.dart';
import 'models/wallet.dart';
import 'recorded_runs.dart';
import 'step_goal.dart';
import 'wallet_repository.dart';

/// Wallet — LIVE from the app backend (shared MongoDB).
///
/// Keyed on the signed-in user so switching accounts refetches instead of
/// showing the previous user's balance from cache.
final walletProvider = FutureProvider<WalletData>((ref) async {
  ref.watch(authControllerProvider.select((AuthState s) => s.user?.id));
  return ref.watch(walletRepositoryProvider).fetch();
});

/// Daily fitness stats, derived **only from runs recorded in FitBox** — not from
/// Apple Health, not from Health Connect, and not from the phone's all-day
/// pedometer.
///
/// Reading the device step counter was tried and deliberately reverted: every
/// part of the product that pays out measures in-app runs. Challenges sum
/// `run.steps`, points are per kilometre run, territory is claimed by the route.
/// A home screen showing 8,000 phone-steps beside a challenge reading
/// "0 / 10,000" would be telling the user two different truths about the same
/// day. The number here is the one the rewards actually count.
///
/// Synchronous, so screens never flash a loading spinner.
final fitnessStatsProvider = Provider<FitnessStats>((ref) {
  final List<RunActivity> runs = ref.watch(recordedRunsProvider);
  final int goal =
      ref.watch(stepGoalProvider).value ?? StepGoalController.fallback;
  final DateTime now = DateTime.now();

  bool sameDay(DateTime d, DateTime o) =>
      d.year == o.year && d.month == o.month && d.day == o.day;
  Iterable<RunActivity> onDay(DateTime day) =>
      runs.where((RunActivity r) => sameDay(r.date, day));

  final Iterable<RunActivity> today = onDay(now);
  return FitnessStats(
    steps: today.fold(0, (int a, RunActivity r) => a + r.steps),
    stepGoal: goal,
    distanceKm: today.fold(0, (double a, RunActivity r) => a + r.distanceKm),
    caloriesKcal: today.fold(0, (int a, RunActivity r) => a + r.caloriesKcal),
    activeMinutes:
        today.fold(0, (int a, RunActivity r) => a + r.duration.inMinutes),
    weeklySteps: List<int>.generate(7, (int i) {
      final DateTime day = now.subtract(Duration(days: 6 - i));
      return onDay(day).fold(0, (int a, RunActivity r) => a + r.steps);
    }),
  );
});
