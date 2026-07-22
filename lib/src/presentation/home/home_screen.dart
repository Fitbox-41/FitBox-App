import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/fitness_stats.dart';
import '../../data/providers.dart';
import '../../data/recorded_runs.dart';
import '../auth/auth_controller.dart';
import '../widgets/common.dart';
import '../widgets/glass.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FitnessStats s = ref.watch(fitnessStatsProvider);
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String? name = ref.watch(authControllerProvider).user?.name;
    final String greeting =
        (name != null && name.isNotEmpty) ? name.split(' ').first : 'athlete';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Text('Hi, $greeting', style: AppText.kinetic(context, size: 26)),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.notifications_none, color: cs.onSurface),
            tooltip: 'Notifications',
            onPressed: () => context.push('/notifications'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(recordedRunsProvider),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          children: <Widget>[
              _StepsRing(stats: s),
              const SizedBox(height: 18),
              GlowButton(
                label: 'Start a run',
                icon: Icons.play_arrow_rounded,
                onPressed: () => _startRun(context),
              ),
              const SizedBox(height: 22),
              Row(
                children: <Widget>[
                  Expanded(
                    child: StatTile(
                      icon: Icons.local_fire_department,
                      value: '${s.caloriesKcal}',
                      animateTo: s.caloriesKcal.toDouble(),
                      animatedFormat: (double v) => '${v.round()}',
                      label: 'kcal',
                      color: FitBoxColors.red,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatTile(
                      icon: Icons.route,
                      value: s.distanceKm.toStringAsFixed(1),
                      animateTo: s.distanceKm,
                      animatedFormat: (double v) => v.toStringAsFixed(1),
                      label: 'km',
                      color: FitBoxColors.credit,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatTile(
                      icon: Icons.timer_outlined,
                      value: '${s.activeMinutes}',
                      animateTo: s.activeMinutes.toDouble(),
                      animatedFormat: (double v) => '${v.round()}',
                      label: 'mins',
                      color: FitBoxColors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _WeeklyCard(weeklySteps: s.weeklySteps),
            ]
                .animate(interval: 70.ms)
                .fadeIn(duration: 320.ms)
                .slideY(begin: 0.12, end: 0, curve: Curves.easeOut),
          ),
        ),
    );
  }

  void _startRun(BuildContext context) => context.push('/record-run');
}

class _StepsRing extends StatelessWidget {
  const _StepsRing({required this.stats});

  final FitnessStats stats;

  @override
  Widget build(BuildContext context) {
    final NumberFormat fmt = NumberFormat.decimalPattern();
    final ColorScheme cs = Theme.of(context).colorScheme;
    return GlassCard(
      radius: 28,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const CardLabel("Today's activity"),
          const SizedBox(height: 8),
          Center(
            child: SizedBox(
              width: 176,
              height: 176,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 1100),
                curve: Curves.easeOutCubic,
                builder: (context, t, _) {
                  final int animatedSteps = (stats.steps * t).round();
                  final double animatedProgress = stats.stepProgress * t;
                  return Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      SizedBox(
                        width: 176,
                        height: 176,
                        child: CircularProgressIndicator(
                          value: animatedProgress,
                          strokeWidth: 13,
                          strokeCap: StrokeCap.round,
                          backgroundColor: cs.onSurface.withValues(alpha: 0.08),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              FitBoxColors.red),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(fmt.format(animatedSteps),
                              style: AppText.data(context,
                                  size: 36, color: cs.onSurface)),
                          const SizedBox(height: 2),
                          Text('/ ${fmt.format(stats.stepGoal)} steps',
                              style: TextStyle(
                                  color: cs.onSurfaceVariant, fontSize: 13)),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text('${(stats.stepProgress * 100).round()}%',
                style: AppText.data(context,
                    size: 15,
                    color: FitBoxColors.red,
                    weight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _WeeklyCard extends StatelessWidget {
  const _WeeklyCard({required this.weeklySteps});

  final List<int> weeklySteps;

  static const List<String> _days = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final int maxSteps =
        weeklySteps.isEmpty ? 1 : weeklySteps.reduce((a, b) => a > b ? a : b);
    return GlassCard(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const CardLabel('This week'),
          const SizedBox(height: 14),
          SizedBox(
            height: 96,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List<Widget>.generate(weeklySteps.length, (int i) {
                final double ratio =
                    maxSteps == 0 ? 0 : weeklySteps[i] / maxSteps;
                final bool today = i == weeklySteps.length - 1;
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Expanded(
                        child: FractionallySizedBox(
                          alignment: Alignment.bottomCenter,
                          heightFactor: ratio.clamp(0.05, 1.0),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            decoration: BoxDecoration(
                              gradient: today
                                  ? const LinearGradient(
                                      colors: <Color>[
                                        FitBoxColors.red,
                                        FitBoxColors.redDark
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    )
                                  : null,
                              color: today
                                  ? null
                                  : cs.onSurface.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(7),
                              boxShadow: today
                                  ? <BoxShadow>[
                                      BoxShadow(
                                        color: FitBoxColors.red
                                            .withValues(alpha: 0.5),
                                        blurRadius: 14,
                                        spreadRadius: -3,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(_days[i % _days.length],
                          style: AppText.labelCaps(context, size: 11)),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
