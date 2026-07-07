/// A snapshot of the user's fitness activity for the day, plus a short weekly
/// history for the dashboard chart.
class FitnessStats {
  const FitnessStats({
    required this.steps,
    required this.stepGoal,
    required this.distanceKm,
    required this.caloriesKcal,
    required this.activeMinutes,
    required this.weeklySteps,
  });

  final int steps;
  final int stepGoal;
  final double distanceKm;
  final int caloriesKcal;
  final int activeMinutes;

  /// Steps for the last seven days, oldest first (length 7).
  final List<int> weeklySteps;

  /// Progress toward the daily step goal, clamped to 0..1.
  double get stepProgress =>
      stepGoal <= 0 ? 0 : (steps / stepGoal).clamp(0.0, 1.0);
}
