import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/fitness_service.dart';
import 'models/fitness_stats.dart';
import 'models/run_activity.dart';
import 'models/wallet.dart';
import 'runs_repository.dart';
import 'wallet_repository.dart';

/// Wallet — LIVE from the app backend (shared MongoDB).
final walletProvider = FutureProvider<WalletData>((ref) async {
  return ref.watch(walletRepositoryProvider).fetch();
});

/// Runs / activity history — LIVE from the app backend.
final runsProvider = FutureProvider<List<RunActivity>>((ref) async {
  return ref.watch(runsRepositoryProvider).fetch();
});

/// Daily fitness stats (steps/calories/distance) — LIVE from the device step
/// sensor on mobile (sample data on web, where no sensor exists).
final fitnessStatsProvider = StreamProvider<FitnessStats>((ref) {
  return ref.watch(fitnessServiceProvider).watch();
});
