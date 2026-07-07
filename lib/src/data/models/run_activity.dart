/// A completed run/workout shown in the activity history.
class RunActivity {
  const RunActivity({
    required this.id,
    required this.title,
    required this.date,
    required this.distanceKm,
    required this.duration,
    required this.caloriesKcal,
  });

  final String id;
  final String title;
  final DateTime date;
  final double distanceKm;
  final Duration duration;
  final int caloriesKcal;

  /// Average pace in minutes per kilometre.
  double get paceMinPerKm =>
      distanceKm <= 0 ? 0 : duration.inSeconds / 60 / distanceKm;
}
