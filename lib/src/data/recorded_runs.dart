import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/secure_storage.dart';
import 'models/run_activity.dart';
import 'runs_repository.dart';

/// The user's runs — everything they've **recorded in the app**. Persisted
/// locally so history shows instantly, and best-effort synced with the backend.
/// Nothing here comes from Apple Health / Health Connect.
class RecordedRuns extends Notifier<List<RunActivity>> {
  static const String _key = 'recorded_runs';

  @override
  List<RunActivity> build() {
    _hydrate();
    return const <RunActivity>[];
  }

  Future<void> _hydrate() async {
    final SecureStorage storage = ref.read(secureStorageProvider);
    List<RunActivity> runs = <RunActivity>[];

    // Local first (instant, offline).
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

    // Merge backend runs (best-effort; dedupe by id).
    try {
      final List<RunActivity> backend =
          await ref.read(runsRepositoryProvider).fetch();
      final Set<String> ids = runs.map((RunActivity r) => r.id).toSet();
      runs = <RunActivity>[
        ...runs,
        ...backend.where((RunActivity r) => !ids.contains(r.id)),
      ];
    } catch (_) {/* offline / not signed in yet */}

    runs.sort((RunActivity a, RunActivity b) => b.date.compareTo(a.date));
    state = runs;
  }

  /// Adds a just-recorded run: shown immediately, persisted, then synced.
  Future<void> addRun(RunActivity run) async {
    state = <RunActivity>[run, ...state]
      ..sort((RunActivity a, RunActivity b) => b.date.compareTo(a.date));
    await _persist();
    try {
      await ref.read(runsRepositoryProvider).save(run);
    } catch (_) {/* keep it locally; a later sync can retry */}
  }

  Future<void> _persist() async {
    await ref.read(secureStorageProvider).write(
          _key,
          jsonEncode(state.map((RunActivity r) => r.toMap()).toList()),
        );
  }
}

final recordedRunsProvider =
    NotifierProvider<RecordedRuns, List<RunActivity>>(RecordedRuns.new);
