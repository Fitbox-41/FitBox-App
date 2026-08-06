import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/secure_storage.dart';
import 'models/run_activity.dart';
import 'models/run_result.dart';
import 'runs_repository.dart';
import 'territory_repository.dart';

/// The user's runs — everything they've **recorded in the app**. Persisted
/// locally so history shows instantly, and best-effort synced with the backend.
/// Nothing here comes from Apple Health / Health Connect.
class RecordedRuns extends Notifier<List<RunActivity>> {
  static const String _key = 'recorded_runs';
  static const String _pendingKey = 'recorded_runs_pending';

  /// Runs recorded locally that the backend hasn't accepted yet. They still owe
  /// the user points and territory, so they're retried on every hydrate.
  Set<String> _pending = <String>{};

  @override
  List<RunActivity> build() {
    _hydrate();
    return const <RunActivity>[];
  }

  Future<void> _hydrate() async {
    final SecureStorage storage = ref.read(secureStorageProvider);

    // Local first — publish immediately so History paints with real data on the
    // first frame instead of waiting on the network (which may time out).
    List<RunActivity> runs = <RunActivity>[];
    final String? raw = await storage.read(_key);
    if (raw != null && raw.isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
        runs = list
            .map((e) =>
                RunActivity.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList();
      } catch (_) {/* ignore corrupt cache */}
    }
    runs.sort((RunActivity a, RunActivity b) => b.date.compareTo(a.date));
    if (runs.isNotEmpty) state = runs;

    final String? pendingRaw = await storage.read(_pendingKey);
    if (pendingRaw != null && pendingRaw.isNotEmpty) {
      try {
        _pending = (jsonDecode(pendingRaw) as List<dynamic>)
            .map((e) => e.toString())
            .toSet();
      } catch (_) {/* ignore corrupt cache */}
    }

    // Then merge the backend's copy in the background (best-effort, dedupe by
    // id). A locally-recorded run and its server copy share the local id via
    // `clientId`, so the same run can't appear twice.
    try {
      final List<RunActivity> backend =
          await ref.read(runsRepositoryProvider).fetch();
      final Set<String> localIds = runs.map((RunActivity r) => r.id).toSet();
      final Set<String> backendIds =
          backend.map((RunActivity r) => r.id).toSet();
      // Any run held only on this phone still owes its owner points and
      // territory, so queue it — this is also what recovers runs recorded by
      // builds whose uploads were failing outright.
      for (final RunActivity r in runs) {
        if (!backendIds.contains(r.id)) _pending.add(r.id);
      }
      runs = <RunActivity>[
        ...runs,
        ...backend.where((RunActivity r) => !localIds.contains(r.id)),
      ];
      runs.sort((RunActivity a, RunActivity b) => b.date.compareTo(a.date));
      state = runs;
      await _persistPending();
    } catch (_) {/* offline / not signed in yet */}

    await _retryPending();
  }

  /// Adds a just-recorded run to local history. Returns as soon as it's stored
  /// on the device — the upload is a separate step so the UI never waits on the
  /// network to show the run.
  Future<void> addRun(RunActivity run) async {
    state = <RunActivity>[run, ...state]
      ..sort((RunActivity a, RunActivity b) => b.date.compareTo(a.date));
    await _persist();
  }

  /// Uploads a run: saves it server-side, claims the territory its route
  /// covered and credits the distance reward. Returns null when the upload
  /// failed — the run is queued and retried on the next app start, so a flaky
  /// connection can't cost the user their land or points.
  Future<RunSyncResult?> syncRun(RunActivity run) async {
    try {
      final RunSyncResult result =
          await ref.read(runsRepositoryProvider).save(run);
      _pending.remove(run.id);
      await _persistPending();
      if (result.claimedAreaSqm > 0) ref.invalidate(territoriesProvider);
      return result;
    } catch (_) {
      _pending.add(run.id);
      await _persistPending();
      return null;
    }
  }

  /// Re-uploads runs that never reached the backend. Safe to call repeatedly:
  /// the server matches on `clientId`, so an already-stored run isn't
  /// duplicated or double-rewarded.
  Future<void> _retryPending() async {
    if (_pending.isEmpty) return;
    final List<RunActivity> queued = state
        .where((RunActivity r) => _pending.contains(r.id))
        .toList();
    bool claimed = false;
    for (final RunActivity r in queued) {
      try {
        final RunSyncResult result =
            await ref.read(runsRepositoryProvider).save(r);
        _pending.remove(r.id);
        if (result.claimedAreaSqm > 0) claimed = true;
      } catch (_) {
        // Keep going: one run that the server rejects (or that times out on a
        // cold start) must not hold back the rest of the queue. Whatever fails
        // stays pending and is tried again next time.
        continue;
      }
    }
    // Drop ids that are no longer in history at all (deleted runs).
    final Set<String> known = state.map((RunActivity r) => r.id).toSet();
    _pending = _pending.where(known.contains).toSet();
    await _persistPending();
    if (claimed) ref.invalidate(territoriesProvider);
  }

  /// Retries any queued uploads — used by pull-to-refresh on History.
  Future<void> retryPendingSyncs() => _retryPending();

  /// How many recorded runs are still waiting to reach the backend.
  int get pendingCount => _pending.length;

  /// Removes a run (local history). Backend has no delete endpoint yet, so this
  /// clears it locally; a re-sync won't resurrect a locally-recorded run.
  Future<void> removeRun(String id) async {
    state = state.where((RunActivity r) => r.id != id).toList();
    _pending.remove(id);
    await _persist();
    await _persistPending();
  }

  Future<void> _persist() async {
    await ref.read(secureStorageProvider).write(
          _key,
          jsonEncode(state.map((RunActivity r) => r.toMap()).toList()),
        );
  }

  Future<void> _persistPending() async {
    await ref
        .read(secureStorageProvider)
        .write(_pendingKey, jsonEncode(_pending.toList()));
  }
}

final recordedRunsProvider =
    NotifierProvider<RecordedRuns, List<RunActivity>>(RecordedRuns.new);
