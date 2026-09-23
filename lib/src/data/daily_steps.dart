import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/secure_storage.dart';

/// Steps taken today, from the phone's own step sensor.
///
/// Until now the app only counted steps *during a recorded run*, so the home
/// ring read 0 all day unless you happened to be tracking one — which is not
/// what a step count means to anyone. This reads the hardware pedometer, the
/// same counter the phone's own health app uses.
///
/// It is **not** a health-platform sync: nothing is read from Apple Health or
/// Health Connect, and no third party is involved. It is the device sensor the
/// app already has permission for, which keeps the project's "only the user's
/// own activity, from this device" rule intact.
///
/// The sensor reports steps since the phone last rebooted, not since midnight.
/// So we store the reading at the first sample of each day and report the
/// difference. Two cases have to be handled or the number goes wrong:
///
///   * **Reboot** — the counter resets to a small number. If the live reading is
///     *below* our baseline, the phone restarted; treat the current reading as
///     today's total rather than reporting a negative.
///   * **A new day** — re-baseline at the first sample after midnight.
class DailySteps {
  const DailySteps({required this.today, required this.available});

  final int today;

  /// False when there's no usable sensor or permission — the UI then says so
  /// instead of showing a confident 0.
  final bool available;
}

class DailyStepsController extends StreamNotifier<DailySteps> {
  static const String _baselineKey = 'steps_baseline';
  static const String _dayKey = 'steps_baseline_day';

  SecureStorage get _storage => ref.read(secureStorageProvider);

  static String _today() {
    final DateTime n = DateTime.now();
    return '${n.year}-${n.month}-${n.day}';
  }

  @override
  Stream<DailySteps> build() async* {
    if (kIsWeb) {
      yield const DailySteps(today: 0, available: false);
      return;
    }

    // Android 10+ gates the step sensor behind activity recognition. Asking
    // here rather than at launch keeps the prompt next to the thing it unlocks.
    try {
      final PermissionStatus status = await Permission.activityRecognition.request();
      if (!status.isGranted) {
        yield const DailySteps(today: 0, available: false);
        return;
      }
    } catch (_) {
      yield const DailySteps(today: 0, available: false);
      return;
    }

    yield const DailySteps(today: 0, available: true);

    await for (final StepCount event in Pedometer.stepCountStream) {
      final int reading = event.steps;
      final String day = _today();
      final String? storedDay = await _storage.read(_dayKey);
      final int? baseline = int.tryParse(await _storage.read(_baselineKey) ?? '');

      int base;
      if (storedDay != day || baseline == null || reading < baseline) {
        // New day, first ever sample, or the phone rebooted (the counter went
        // backwards). Start counting from here.
        base = reading;
        await _storage.write(_baselineKey, '$reading');
        await _storage.write(_dayKey, day);
      } else {
        base = baseline;
      }
      yield DailySteps(today: reading - base, available: true);
    }
  }
}

final dailyStepsProvider =
    StreamNotifierProvider<DailyStepsController, DailySteps>(
  DailyStepsController.new,
);

/// The daily step target, which the user sets by tapping the ring on Home.
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
