import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/fitness_stats.dart';
import 'models/run_activity.dart';
import 'models/wallet.dart';
import 'mock_data.dart';
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

/// Daily fitness stats (steps/calories/distance) — still mock; these will come
/// from device sensors + health data, not the backend.
final fitnessStatsProvider = FutureProvider<FitnessStats>((ref) async {
  await Future<void>.delayed(const Duration(milliseconds: 400));
  return MockData.fitnessStats;
});
