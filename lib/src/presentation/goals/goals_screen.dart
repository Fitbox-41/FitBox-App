import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/run_activity.dart';
import '../../data/models/territory.dart';
import '../../data/providers.dart';
import '../../data/recorded_runs.dart';
import '../../data/territory_repository.dart';
import '../auth/auth_controller.dart';
import '../widgets/common.dart';
import '../widgets/glass.dart';
import '../widgets/motion.dart';

/// Targets and achievements, all computed from the user's own recorded runs —
/// nothing here is illustrative.
class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  // Targets. Steps are per day; distance and runs are per week.
  static const int _dailyStepGoal = 8000;
  static const double _weeklyDistanceGoalKm = 20;
  static const int _weeklyRunGoal = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<RunActivity> runs = ref.watch(recordedRunsProvider);
    final int todaySteps = ref.watch(fitnessStatsProvider).steps;

    // "This week" = the last 7 days, matching the weekly chart on History.
    final DateTime weekStart =
        DateTime.now().subtract(const Duration(days: 6));
    final Iterable<RunActivity> thisWeek = runs.where((RunActivity r) =>
        r.date.isAfter(DateTime(weekStart.year, weekStart.month, weekStart.day)));
    final double weekKm =
        thisWeek.fold(0.0, (double a, RunActivity r) => a + r.distanceKm);
    final int weekRuns = thisWeek.length;

    final double totalKm =
        runs.fold(0.0, (double a, RunActivity r) => a + r.distanceKm);
    final double bestPace = runs
        .where((RunActivity r) => r.paceMinPerKm > 0)
        .fold(double.infinity,
            (double a, RunActivity r) => r.paceMinPerKm < a ? r.paceMinPerKm : a);

    // Territory-based achievements come from the shared map.
    final String? myId = ref.watch(authControllerProvider).user?.id;
    final double myArea = ref.watch(territoriesProvider).maybeWhen(
          data: (TerritorySnapshot s) => s.areas
              .where((TerritoryArea t) => t.userId == myId)
              .fold(0.0, (double a, TerritoryArea t) => a + t.area),
          orElse: () => 0.0,
        );
    final int myRank = ref.watch(territoriesProvider).maybeWhen(
          data: (TerritorySnapshot s) {
            final List<TerritoryArea> ranked = <TerritoryArea>[...s.areas]
              ..sort((TerritoryArea a, TerritoryArea b) =>
                  b.area.compareTo(a.area));
            return ranked.indexWhere((TerritoryArea t) => t.userId == myId) + 1;
          },
          orElse: () => 0,
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Goals')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(recordedRunsProvider);
          ref.invalidate(territoriesProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: <Widget>[
            const SectionHeader('Targets'),
            _GoalCard(
              label: 'Daily steps',
              value: '${_fmtInt(todaySteps)} / ${_fmtInt(_dailyStepGoal)}',
              progress: (todaySteps / _dailyStepGoal).clamp(0.0, 1.0),
            ),
            const SizedBox(height: 12),
            _GoalCard(
              label: 'Weekly distance',
              value:
                  '${weekKm.toStringAsFixed(1)} / ${_weeklyDistanceGoalKm.toStringAsFixed(0)} km',
              progress: (weekKm / _weeklyDistanceGoalKm).clamp(0.0, 1.0),
            ),
            const SizedBox(height: 12),
            _GoalCard(
              label: 'Weekly runs',
              value: '$weekRuns / $_weeklyRunGoal runs',
              progress: (weekRuns / _weeklyRunGoal).clamp(0.0, 1.0),
            ),
            const SizedBox(height: 28),
            const SectionHeader('Achievements'),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: <Widget>[
                _Badge(
                    icon: Icons.bolt,
                    label: 'First run',
                    unlocked: runs.isNotEmpty),
                _Badge(
                    icon: Icons.local_fire_department,
                    label: '3-day streak',
                    unlocked: _longestStreak(runs) >= 3),
                _Badge(
                    icon: Icons.terrain,
                    label: '10 km club',
                    unlocked: totalKm >= 10),
                _Badge(
                    icon: Icons.map,
                    label: 'Landowner',
                    unlocked: myArea >= 100000), // 0.1 km² held
                _Badge(
                    icon: Icons.speed,
                    label: 'Sub-6 pace',
                    unlocked: bestPace.isFinite && bestPace < 6),
                _Badge(
                    icon: Icons.emoji_events,
                    label: 'Top of the map',
                    unlocked: myRank == 1),
              ],
            ),
          ].revealStagger(),
        ),
      ),
    );
  }

  static String _fmtInt(int v) => v.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'), (Match m) => '${m[1]},');

  /// Longest run of consecutive days with at least one recorded run.
  static int _longestStreak(List<RunActivity> runs) {
    if (runs.isEmpty) return 0;
    final Set<int> days = runs
        .map((RunActivity r) =>
            DateTime(r.date.year, r.date.month, r.date.day)
                .millisecondsSinceEpoch ~/
            86400000)
        .toSet();
    final List<int> sorted = days.toList()..sort();
    int best = 1;
    int current = 1;
    for (int i = 1; i < sorted.length; i++) {
      if (sorted[i] == sorted[i - 1] + 1) {
        current += 1;
        if (current > best) best = current;
      } else {
        current = 1;
      }
    }
    return best;
  }
}

/// A single goal target as a glass card: an animated brand-red progress ring
/// with a counting percentage, the target value in Oswald, and a clean label.
class _GoalCard extends StatelessWidget {
  const _GoalCard(
      {required this.label, required this.value, required this.progress});

  final String label;
  final String value;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return GlassCard(
      radius: 24,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 66,
            height: 66,
            // The ring fill and the percentage numeral share one driver so they
            // animate up together on reveal.
            child: CountUpText(
              value: progress,
              duration: const Duration(milliseconds: 1100),
              builder: (BuildContext context, double v) => Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  SizedBox(
                    width: 66,
                    height: 66,
                    child: CircularProgressIndicator(
                      value: v,
                      strokeWidth: 7,
                      strokeCap: StrokeCap.round,
                      backgroundColor: cs.onSurface.withValues(alpha: 0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          FitBoxColors.red),
                    ),
                  ),
                  Text('${(v * 100).round()}%',
                      style: AppText.data(context, size: 15)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label.toUpperCase(),
                    style: AppText.labelCaps(context, size: 11)),
                const SizedBox(height: 6),
                Text(value,
                    style: AppText.data(context, size: 26, color: cs.onSurface)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(
      {required this.icon, required this.label, required this.unlocked});

  final IconData icon;
  final String label;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return GlassCard(
      radius: 20,
      padding: const EdgeInsets.all(10),
      onTap: () => HapticFeedback.selectionClick(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: unlocked
                  ? FitBoxColors.red.withValues(alpha: 0.16)
                  : cs.onSurface.withValues(alpha: 0.05),
              boxShadow: unlocked
                  ? <BoxShadow>[
                      BoxShadow(
                        color: FitBoxColors.red.withValues(alpha: 0.28),
                        blurRadius: 16,
                        spreadRadius: -4,
                      ),
                    ]
                  : null,
            ),
            child: Icon(icon,
                size: 26,
                color: unlocked
                    ? FitBoxColors.red
                    : cs.onSurface.withValues(alpha: 0.25)),
          ),
          const SizedBox(height: 8),
          Text(label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption(
                size: 11,
                color: unlocked ? cs.onSurface : cs.onSurfaceVariant,
              )),
        ],
      ),
    );
  }
}
