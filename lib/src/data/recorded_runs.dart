import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../presentation/auth/auth_controller.dart';
import '../services/secure_storage.dart';
import 'models/run_activity.dart';
import 'models/run_result.dart';
import 'runs_repository.dart';
import 'territory_repository.dart';

/// The user's runs — everything **they** recorded in the app. Persisted locally
/// so history shows instantly, and best-effort synced with the backend. Nothing
/// here comes from Apple Health / Health Connect.
///
/// Storage is **per account**. It used to be one shared key, which meant signing
/// in as a second user showed the first user's runs as their own — and, once
/// unsynced runs started being retried, uploaded them under the wrong account,
/// handing over their points and territory. History is therefore keyed by user
/// id, reset whenever the signed-in user changes, and a run is only ever
/// uploaded by the account that recorded it.
class RecordedRuns extends Notifier<List<RunActivity>> {
  static const String _legacyKey = 'recorded_runs';
  static const String _legacyPendingKey = 'recorded_runs_pending';

  static String _keyFor(String userId) => 'recorded_runs_$userId';
  static String _pendingKeyFor(String userId) => 'recorded_runs_pending_$userId';

  /// The account this history belongs to. Null when signed out — nothing is
  /// read, written or uploaded in that state.
  String? _userId;

  /// Runs recorded locally that the backend hasn't accepted yet. They still owe
  /// the user points and territory, so they're retried on every hydrate.
  Set<String> _pending = <String>{};

  @override
  List<RunActivity> build() {
    // Rebuild whenever the signed-in user changes, so one account's history can
    // never be shown — or synced — under another's.
    final String? userId = ref.watch(authControllerProvider).user?.id;
    _userId = userId;
    _pending = <String>{};
    if (userId == null) return const <RunActivity>[];
    _hydrate(userId);
    return const <RunActivity>[];
  }

  Future<void> _hydrate(String userId) async {
    final SecureStorage storage = ref.read(secureStorageProvider);

    // Drop the pre-per-user cache. Those runs were already uploaded under
    // whichever account recorded them, so they come back from the backend for
    // their real owner — keeping them would re-attribute them to whoever signs
    // in next.
    await storage.delete(_legacyKey);
    await storage.delete(_legacyPendingKey);

    // Local first — publish immediately so History paints with real data on the
    // first frame instead of waiting on the network (which may time out).
    List<RunActivity> runs = <RunActivity>[];
    final String? raw = await storage.read(_keyFor(userId));
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
    if (_userId != userId) return; // user switched mid-read
    if (runs.isNotEmpty) state = runs;

    final String? pendingRaw = await storage.read(_pendingKeyFor(userId));
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
      if (_userId != userId) return; // user switched mid-fetch
      final Set<String> localIds = runs.map((RunActivity r) => r.id).toSet();
      final Set<String> backendIds =
          backend.map((RunActivity r) => r.id).toSet();
      // Any run held only on this phone still owes its owner points and
      // territory, so queue it — this is also what recovers runs recorded by
      // builds whose uploads were failing outright. Safe now that history is
      // per-account: these can only be this user's own runs.
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
    if (_userId == null) return; // guest / signed out — nothing to attribute it to
    state = <RunActivity>[run, ...state]
      ..sort((RunActivity a, RunActivity b) => b.date.compareTo(a.date));
    await _persist();
  }

  /// Uploads a run: saves it server-side, claims the territory its route
  /// covered and credits any reward. Returns null when the upload failed — the
  /// run is queued and retried on the next app start, so a flaky connection
  /// can't cost the user their land.
  Future<RunSyncResult?> syncRun(RunActivity run) async {
    final String? userId = _userId;
    if (userId == null) return null;
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
    if (_pending.isEmpty || _userId == null) return;
    final String userId = _userId!;
    final List<RunActivity> queued = state
        .where((RunActivity r) => _pending.contains(r.id))
        .toList();
    bool claimed = false;
    for (final RunActivity r in queued) {
      if (_userId != userId) return; // user switched mid-retry
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

  /// Removes a run from history, locally and on the server, so a later sync
  /// can't bring it back. The local copy goes first — deleting must feel
  /// immediate and must work offline; if the server call fails the run is gone
  /// from this device and the next fetch simply re-adds it.
  Future<void> removeRun(String id) async {
    state = state.where((RunActivity r) => r.id != id).toList();
    _pending.remove(id);
    await _persist();
    await _persistPending();
    try {
      await ref.read(runsRepositoryProvider).delete(id);
    } catch (_) {/* offline — history is already correct on this device */}
  }

  Future<void> _persist() async {
    final String? userId = _userId;
    if (userId == null) return;
    await ref.read(secureStorageProvider).write(
          _keyFor(userId),
          jsonEncode(state.map((RunActivity r) => r.toMap()).toList()),
        );
  }

  Future<void> _persistPending() async {
    final String? userId = _userId;
    if (userId == null) return;
    await ref
        .read(secureStorageProvider)
        .write(_pendingKeyFor(userId), jsonEncode(_pending.toList()));
  }
}

final recordedRunsProvider =
    NotifierProvider<RecordedRuns, List<RunActivity>>(RecordedRuns.new);
