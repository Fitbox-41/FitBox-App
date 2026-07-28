/// A challenge as returned by the app backend, with this user's status.
class Challenge {
  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.goalType,
    required this.goalTarget,
    required this.durationDays,
    required this.rewardPoints,
    required this.userCap,
    required this.rewardedSoFar,
    required this.joined,
    required this.progress,
    required this.completed,
    required this.claimed,
    required this.canClaim,
    required this.capReached,
    this.deadline,
  });

  final String id;
  final String title;
  final String description;
  final String goalType; // 'steps' | 'distance'
  final double goalTarget; // steps count or km
  final int durationDays;
  final int rewardPoints;
  final int userCap; // 0 = unlimited
  final int rewardedSoFar;
  final bool joined;
  final double progress;
  final bool completed;
  final bool claimed;
  final bool canClaim;
  final bool capReached;
  final DateTime? deadline;

  bool get isDistance => goalType == 'distance';

  double get progressFraction =>
      goalTarget <= 0 ? 0 : (progress / goalTarget).clamp(0.0, 1.0);

  String get goalLabel => isDistance
      ? '${_trim(goalTarget)} km'
      : '${goalTarget.round()} steps';

  String get progressLabel => isDistance
      ? '${progress.toStringAsFixed(2)} / ${_trim(goalTarget)} km'
      : '${progress.round()} / ${goalTarget.round()} steps';

  static String _trim(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);

  factory Challenge.fromJson(Map<String, dynamic> j) => Challenge(
        id: (j['id'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        description: (j['description'] ?? '').toString(),
        goalType: (j['goalType'] ?? 'steps').toString(),
        goalTarget: (j['goalTarget'] as num?)?.toDouble() ?? 0,
        durationDays: (j['durationDays'] as num?)?.toInt() ?? 0,
        rewardPoints: (j['rewardPoints'] as num?)?.toInt() ?? 0,
        userCap: (j['userCap'] as num?)?.toInt() ?? 0,
        rewardedSoFar: (j['rewardedSoFar'] as num?)?.toInt() ?? 0,
        joined: j['joined'] == true,
        progress: (j['progress'] as num?)?.toDouble() ?? 0,
        completed: j['completed'] == true,
        claimed: j['claimed'] == true,
        canClaim: j['canClaim'] == true,
        capReached: j['capReached'] == true,
        deadline: j['deadline'] != null
            ? DateTime.tryParse(j['deadline'].toString())?.toLocal()
            : null,
      );
}
