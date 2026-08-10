import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../presentation/auth/auth_controller.dart';
import 'models/fitness_stats.dart';
import 'models/run_activity.dart';
import 'models/wallet.dart';
import 'recorded_runs.dart';
import 'wallet_repository.dart';

/// Wallet — LIVE from the app backend (shared MongoDB).
///
/// Keyed on the signed-in user so switching accounts refetches instead of
/// showing the previous user's balance from cache.
final walletProvider = FutureProvider<WalletData>((ref) async {
  ref.watch(authControllerProvider.select((AuthState s) => s.user?.id));
  return ref.watch(walletRepositoryProvider).fetch();
});

/// Daily fitness stats derived **only from the user's in-app recorded runs** —
/// never from Apple Health / Health Connect. Synchronous, so screens never flash
/// a loading spinner.
final fitnessStatsProvider = Provider<FitnessStats>((ref) {
  final List<RunActivity> runs = ref.watch(recordedRunsProvider);
  final DateTime now = DateTime.now();

  bool sameDay(DateTime d, DateTime o) =>
      d.year == o.year && d.month == o.month && d.day == o.day;
  Iterable<RunActivity> onDay(DateTime day) =>
      runs.where((RunActivity r) => sameDay(r.date, day));

  final Iterable<RunActivity> today = onDay(now);
  return FitnessStats(
    steps: today.fold(0, (int a, RunActivity r) => a + r.steps),
    stepGoal: 10000,
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
