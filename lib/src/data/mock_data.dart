import 'models/fitness_stats.dart';
import 'models/run_activity.dart';
import 'models/wallet.dart';

/// Hard-coded sample data used while the app runs against mocks. This is
/// replaced by real API calls once the live backend is connected.
class MockData {
  const MockData._();

  static const FitnessStats fitnessStats = FitnessStats(
    steps: 7432,
    stepGoal: 10000,
    distanceKm: 5.2,
    caloriesKcal: 384,
    activeMinutes: 47,
    weeklySteps: <int>[6200, 8100, 7500, 9800, 5400, 10200, 7432],
  );

  static const WalletBalance walletBalance = WalletBalance(points: 1250);

  static List<WalletTransaction> walletTransactions() => <WalletTransaction>[
        WalletTransaction(
          id: 't1',
          type: WalletTxType.credit,
          amount: 150,
          description: 'Territory captured — Riverside loop',
          date: DateTime(2026, 7, 6, 8, 12),
        ),
        WalletTransaction(
          id: 't2',
          type: WalletTxType.credit,
          amount: 100,
          description: 'Weekly distance goal reached',
          date: DateTime(2026, 7, 5, 19, 40),
        ),
        WalletTransaction(
          id: 't3',
          type: WalletTxType.debit,
          amount: 300,
          description: 'Redeemed at checkout — order #10482',
          date: DateTime(2026, 7, 3, 12, 5),
        ),
        WalletTransaction(
          id: 't4',
          type: WalletTxType.credit,
          amount: 200,
          description: 'First run bonus',
          date: DateTime(2026, 7, 1, 7, 30),
        ),
      ];

  static List<RunActivity> runs() => <RunActivity>[
        RunActivity(
          id: 'r1',
          title: 'Morning run',
          date: DateTime(2026, 7, 6, 7, 45),
          distanceKm: 5.2,
          duration: Duration(minutes: 28, seconds: 30),
          caloriesKcal: 384,
        ),
        RunActivity(
          id: 'r2',
          title: 'Evening jog',
          date: DateTime(2026, 7, 5, 18, 20),
          distanceKm: 3.8,
          duration: Duration(minutes: 22, seconds: 10),
          caloriesKcal: 271,
        ),
        RunActivity(
          id: 'r3',
          title: 'Long run',
          date: DateTime(2026, 7, 3, 6, 50),
          distanceKm: 8.1,
          duration: Duration(minutes: 47, seconds: 5),
          caloriesKcal: 602,
        ),
      ];
}
