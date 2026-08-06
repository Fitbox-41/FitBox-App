import 'run_activity.dart';

/// What the backend did with a synced run: the land it claimed, the points it
/// earned, and why it claimed nothing (when it didn't).
class RunSyncResult {
  const RunSyncResult({
    this.claimedAreaSqm = 0,
    this.pointsAwarded = 0,
    this.territoryMessage,
  });

  final double claimedAreaSqm;
  final int pointsAwarded;

  /// Server explanation when a run claimed no territory (e.g. too short).
  final String? territoryMessage;
}

/// Passed to the Run Summary screen after finishing a run.
///
/// The run is already saved locally, so the summary opens instantly; [sync] is
/// the in-flight upload, and the screen fills in the claimed territory and
/// points when it lands. It resolves to null if the upload failed — the run is
/// kept locally and retried later.
class RunResult {
  const RunResult({required this.run, this.sync, this.claimedAreaSqm});

  final RunActivity run;
  final Future<RunSyncResult?>? sync;

  /// Already-known claimed area (used when reopening a past run).
  final double? claimedAreaSqm;
}
