import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mock_data.dart';
import 'models/fitness_stats.dart';
import 'models/run_activity.dart';
import 'models/wallet.dart';

/// These providers currently return mock data after a short delay so the UI
/// exercises real loading/error states. When the live backend is ready, only
/// the bodies here change (to `dio` calls) — the screens stay the same.

const Duration _fakeLatency = Duration(milliseconds: 600);

final fitnessStatsProvider = FutureProvider<FitnessStats>((ref) async {
  await Future<void>.delayed(_fakeLatency);
  return MockData.fitnessStats;
});

final walletBalanceProvider = FutureProvider<WalletBalance>((ref) async {
  await Future<void>.delayed(_fakeLatency);
  return MockData.walletBalance;
});

final walletTransactionsProvider =
    FutureProvider<List<WalletTransaction>>((ref) async {
  await Future<void>.delayed(_fakeLatency);
  return MockData.walletTransactions();
});

final runsProvider = FutureProvider<List<RunActivity>>((ref) async {
  await Future<void>.delayed(_fakeLatency);
  return MockData.runs();
});
