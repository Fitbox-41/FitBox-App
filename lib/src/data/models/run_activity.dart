/// A completed run/workout — always **recorded in-app** by the user (never
/// synced from Apple Health / Health Connect).
class RunActivity {
  const RunActivity({
    required this.id,
    required this.title,
    required this.date,
    required this.distanceKm,
    required this.duration,
    required this.caloriesKcal,
    this.steps = 0,
  });

  final String id;
  final String title;
  final DateTime date;
  final double distanceKm;
  final Duration duration;
  final int caloriesKcal;
  final int steps;

  /// Average pace in minutes per kilometre.
  double get paceMinPerKm =>
      distanceKm <= 0 ? 0 : duration.inSeconds / 60 / distanceKm;

  RunActivity copyWith({String? id, String? title}) => RunActivity(
        id: id ?? this.id,
        title: title ?? this.title,
        date: date,
        distanceKm: distanceKm,
        duration: duration,
        caloriesKcal: caloriesKcal,
        steps: steps,
      );

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
      steps: (json['steps'] as num?)?.toInt() ?? 0,
    );
  }

  /// Payload for the app backend (`POST /api/runs`): distance in metres,
  /// duration in seconds, ISO start time.
  Map<String, dynamic> toBackendJson() => <String, dynamic>{
        'title': title,
        'distance': (distanceKm * 1000).round(),
        'duration': duration.inSeconds,
        'calories': caloriesKcal,
        'steps': steps,
        'startedAt': date.toUtc().toIso8601String(),
      };

  /// Compact map for local persistence (kilometres/seconds kept as-is).
  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'title': title,
        'date': date.toIso8601String(),
        'km': distanceKm,
        'seconds': duration.inSeconds,
        'calories': caloriesKcal,
        'steps': steps,
      };

  factory RunActivity.fromMap(Map<String, dynamic> m) => RunActivity(
        id: (m['id'] ?? '').toString(),
        title: (m['title'] ?? 'Run').toString(),
        date: DateTime.tryParse(m['date']?.toString() ?? '') ?? DateTime.now(),
        distanceKm: (m['km'] as num?)?.toDouble() ?? 0,
        duration: Duration(seconds: (m['seconds'] as num?)?.toInt() ?? 0),
        caloriesKcal: (m['calories'] as num?)?.toInt() ?? 0,
        steps: (m['steps'] as num?)?.toInt() ?? 0,
      );
}
