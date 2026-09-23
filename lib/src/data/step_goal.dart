import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/secure_storage.dart';

/// The daily step target, which the user sets by tapping the ring on Home.
///
/// Stored per device rather than on the account: it's a personal nudge, not
/// something the rewards system reads, so there's nothing to keep in sync
/// server-side.
///
/// Note what this is a goal *for* — steps recorded during runs tracked in
/// FitBox, not the phone's all-day pedometer. See [fitnessStatsProvider].
class StepGoalController extends AsyncNotifier<int> {
  static const String _key = 'step_goal';
  static const int fallback = 10000;

  @override
  Future<int> build() async {
    final String? raw = await ref.read(secureStorageProvider).read(_key);
    return int.tryParse(raw ?? '') ?? fallback;
  }

  Future<void> set(int goal) async {
    final int clamped = goal.clamp(1000, 100000);
    await ref.read(secureStorageProvider).write(_key, '$clamped');
    state = AsyncData<int>(clamped);
  }
}

final stepGoalProvider =
    AsyncNotifierProvider<StepGoalController, int>(StepGoalController.new);
