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

  /// Parses a run as stored by the app backend (distance in metres, duration in
  /// seconds).
  factory RunActivity.fromJson(Map<String, dynamic> json) {
    final metres = (json['distance'] as num?)?.toDouble() ?? 0;
    final seconds = (json['duration'] as num?)?.toInt() ?? 0;
    return RunActivity(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? 'Run').toString(),
      date: DateTime.tryParse(json['startedAt']?.toString() ?? '')?.toLocal() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      distanceKm: metres / 1000,
      duration: Duration(seconds: seconds),
      caloriesKcal: (json['calories'] as num?)?.round() ?? 0,
    );
  }
}
