import 'run_activity.dart';

/// Passed to the Run Summary screen after finishing a run: the run itself plus
/// the territory area claimed by this run's loop (null if nothing was claimed —
/// guest, no loop, or offline).
class RunResult {
  const RunResult({required this.run, this.claimedAreaSqm});

  final RunActivity run;
  final double? claimedAreaSqm;
}
