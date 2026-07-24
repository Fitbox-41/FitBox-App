import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/run_notifier.dart';
import 'models/geo_point.dart';
import 'models/run_activity.dart';

enum RunStatus { idle, running, paused }

/// Live state of an in-app run the user is recording.
class RunSession {
  const RunSession({
    required this.status,
    required this.elapsed,
    required this.steps,
    this.startedAt,
    this.route = const <GeoPoint>[],
    this.gpsMetres = 0,
  });

  final RunStatus status;
  final Duration elapsed;
  final int steps;
  final DateTime? startedAt;

  /// GPS route sampled during the run (empty until the first fix / indoors).
  final List<GeoPoint> route;

  /// Distance accumulated from GPS, in metres.
  final double gpsMetres;

  // Fallbacks when there's no GPS (indoor / no fix): step-derived metrics.
  static const double _strideMetres = 0.762;
  static const double _kcalPerStep = 0.045;

  /// Prefer real GPS distance once we have a route; fall back to step-derived.
  double get distanceKm =>
      gpsMetres > 0 ? gpsMetres / 1000 : steps * _strideMetres / 1000;
  int get calories => (steps * _kcalPerStep).round();
  double get paceMinPerKm =>
      distanceKm <= 0 ? 0 : elapsed.inSeconds / 60 / distanceKm;

  RunSession copyWith({
    RunStatus? status,
    Duration? elapsed,
    int? steps,
    DateTime? startedAt,
    List<GeoPoint>? route,
    double? gpsMetres,
  }) =>
      RunSession(
        status: status ?? this.status,
        elapsed: elapsed ?? this.elapsed,
        steps: steps ?? this.steps,
        startedAt: startedAt ?? this.startedAt,
        route: route ?? this.route,
        gpsMetres: gpsMetres ?? this.gpsMetres,
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

  // GPS route recording.
  StreamSubscription<Position>? _posSub;
  final List<GeoPoint> _route = <GeoPoint>[];
  double _gpsMetres = 0;
  Position? _lastPos;

  @override
  RunSession build() {
    ref.onDispose(_teardown);
    return RunSession.idle;
  }

  Future<void> start() async {
    await _ensurePermission();
    _committedSteps = 0;
    _segmentBaseline = null;
    _route.clear();
    _gpsMetres = 0;
    _lastPos = null;
    state = RunSession(
      status: RunStatus.running,
      elapsed: Duration.zero,
      steps: 0,
      startedAt: DateTime.now(),
    );
    _startTimer();
    _listenSteps();
    _listenPositions();
    _pushNotification();
  }

  void pause() {
    if (state.status != RunStatus.running) return;
    _committedSteps = state.steps; // bank steps so far
    _segmentBaseline = null; // re-baseline on resume
    _lastPos = null; // don't bridge a straight line across the pause gap
    _timer?.cancel();
    state = state.copyWith(status: RunStatus.paused);
    _pushNotification();
  }

  void resume() {
    if (state.status != RunStatus.paused) return;
    _segmentBaseline = null;
    state = state.copyWith(status: RunStatus.running);
    _startTimer();
    _pushNotification();
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
      route: s.route,
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
        _pushNotification();
      }
    });
  }

  // ---- live notification ----

  String _fmtElapsed(Duration d) {
    final String mm = (d.inMinutes % 60).toString().padLeft(2, '0');
    final String ss = (d.inSeconds % 60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:$mm:$ss' : '$mm:$ss';
  }

  String _fmtPace(double p) {
    if (p <= 0) return "0'00";
    final int m = p.floor();
    return "$m'${((p - m) * 60).round().toString().padLeft(2, '0')}";
  }

  void _pushNotification() {
    final RunSession s = state;
    final bool paused = s.status == RunStatus.paused;
    final String body =
        '${_fmtElapsed(s.elapsed)}  ·  ${s.distanceKm.toStringAsFixed(2)} km  ·  ${_fmtPace(s.paceMinPerKm)}/km';
    ref.read(runNotifierProvider).update(
          title: paused ? 'FitBox — paused' : 'FitBox — recording run',
          body: body,
        );
  }

  /// Streams GPS fixes while running: appends to the route and accumulates real
  /// distance (jitter/outlier-filtered). Silently no-ops without permission or a
  /// location fix (indoor / emulator) — the run still records via the timer.
  Future<void> _listenPositions() async {
    if (kIsWeb) return;
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }
      if (!await Geolocator.isLocationServiceEnabled()) return;

      _posSub?.cancel();
      _posSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 4, // metres between updates
        ),
      ).listen((Position pos) {
        if (state.status != RunStatus.running) {
          _lastPos = null; // paused — restart the segment on resume
          return;
        }
        if (_lastPos != null) {
          final double d = Geolocator.distanceBetween(
            _lastPos!.latitude,
            _lastPos!.longitude,
            pos.latitude,
            pos.longitude,
          );
          // Ignore GPS jitter (<2 m) and implausible jumps (>100 m per fix).
          if (d >= 2 && d < 100) _gpsMetres += d;
        }
        _lastPos = pos;
        _route.add(GeoPoint(pos.latitude, pos.longitude));
        state = state.copyWith(
          route: List<GeoPoint>.unmodifiable(_route),
          gpsMetres: _gpsMetres,
        );
      }, onError: (_) {/* no fix — timer/steps still record the run */});
    } catch (_) {/* location unavailable */}
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
    _posSub?.cancel();
    _posSub = null;
    ref.read(runNotifierProvider).clear();
  }
}

final runSessionProvider =
    NotifierProvider<RunSessionController, RunSession>(RunSessionController.new);
