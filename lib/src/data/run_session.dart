import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

import 'models/run_activity.dart';

enum RunStatus { idle, running, paused }

/// Live state of an in-app run the user is recording.
class RunSession {
  const RunSession({
    required this.status,
    required this.elapsed,
    required this.steps,
    this.startedAt,
  });

  final RunStatus status;
  final Duration elapsed;
  final int steps;
  final DateTime? startedAt;

  // Step-derived metrics (no GPS yet — distance comes from the step sensor).
  static const double _strideMetres = 0.762;
  static const double _kcalPerStep = 0.045;

  double get distanceKm => steps * _strideMetres / 1000;
  int get calories => (steps * _kcalPerStep).round();
  double get paceMinPerKm =>
      distanceKm <= 0 ? 0 : elapsed.inSeconds / 60 / distanceKm;

  RunSession copyWith({
    RunStatus? status,
    Duration? elapsed,
    int? steps,
    DateTime? startedAt,
  }) =>
      RunSession(
        status: status ?? this.status,
        elapsed: elapsed ?? this.elapsed,
        steps: steps ?? this.steps,
        startedAt: startedAt ?? this.startedAt,
      );

  static const RunSession idle = RunSession(
      status: RunStatus.idle, elapsed: Duration.zero, steps: 0);
}

/// Records a run in-app: a per-second timer for duration + the device step
/// sensor (only while recording) for steps → distance/pace/calories. This is the
/// ONLY way activity enters the app — nothing is synced from Apple Health /
/// Health Connect.
class RunSessionController extends Notifier<RunSession> {
  Timer? _timer;
  StreamSubscription<StepCount>? _sub;
  int _committedSteps = 0; // steps banked from finished running segments
  int? _segmentBaseline; // cumulative sensor count at current segment start

  @override
  RunSession build() {
    ref.onDispose(_teardown);
    return RunSession.idle;
  }

  Future<void> start() async {
    await _ensurePermission();
    _committedSteps = 0;
    _segmentBaseline = null;
    state = RunSession(
      status: RunStatus.running,
      elapsed: Duration.zero,
      steps: 0,
      startedAt: DateTime.now(),
    );
    _startTimer();
    _listenSteps();
  }

  void pause() {
    if (state.status != RunStatus.running) return;
    _committedSteps = state.steps; // bank steps so far
    _segmentBaseline = null; // re-baseline on resume
    _timer?.cancel();
    state = state.copyWith(status: RunStatus.paused);
  }

  void resume() {
    if (state.status != RunStatus.paused) return;
    _segmentBaseline = null;
    state = state.copyWith(status: RunStatus.running);
    _startTimer();
  }

  /// Ends the session and returns the recorded run (caller persists it).
  RunActivity finish() {
    final RunSession s = state;
    final DateTime when = s.startedAt ?? DateTime.now();
    final RunActivity run = RunActivity(
      id: 'local-${when.microsecondsSinceEpoch}',
      title: _titleFor(when),
      date: when,
      distanceKm: s.distanceKm,
      duration: s.elapsed,
      caloriesKcal: s.calories,
      steps: s.steps,
    );
    _teardown();
    state = RunSession.idle;
    return run;
  }

  void discard() {
    _teardown();
    state = RunSession.idle;
  }

  // ---- internals ----

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.status == RunStatus.running) {
        state = state.copyWith(
            elapsed: state.elapsed + const Duration(seconds: 1));
      }
    });
  }

  void _listenSteps() {
    _sub?.cancel();
    try {
      _sub = Pedometer.stepCountStream.listen((StepCount e) {
        if (state.status != RunStatus.running) return;
        _segmentBaseline ??= e.steps;
        final int segment = e.steps - _segmentBaseline!;
        state = state
            .copyWith(steps: _committedSteps + (segment < 0 ? 0 : segment));
      }, onError: (_) {/* no sensor (emulator/web) — duration still counts */});
    } catch (_) {/* platform without a step sensor */}
  }

  Future<void> _ensurePermission() async {
    if (kIsWeb) return;
    if (defaultTargetPlatform == TargetPlatform.android) {
      await Permission.activityRecognition.request();
    }
  }

  String _titleFor(DateTime t) {
    final int h = t.hour;
    if (h < 12) return 'Morning run';
    if (h < 17) return 'Afternoon run';
    return 'Evening run';
  }

  void _teardown() {
    _timer?.cancel();
    _timer = null;
    _sub?.cancel();
    _sub = null;
  }
}

final runSessionProvider =
    NotifierProvider<RunSessionController, RunSession>(RunSessionController.new);
