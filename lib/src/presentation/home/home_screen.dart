import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/fitness_stats.dart';
import '../../data/providers.dart';
import '../auth/auth_controller.dart';
import '../widgets/common.dart';
import '../widgets/glass.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<FitnessStats> stats = ref.watch(fitnessStatsProvider);
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String? name = ref.watch(authControllerProvider).user?.name;
    final String greeting =
        (name != null && name.isNotEmpty) ? name.split(' ').first : 'athlete';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Welcome back',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            Text('Hi, $greeting',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface)),
          ],
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.notifications_none, color: cs.onSurface),
            onPressed: () {},
          ),
        ],
      ),
      body: stats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, _) => AsyncRetry(
          message: "Couldn't load your stats.",
          onRetry: () => ref.invalidate(fitnessStatsProvider),
        ),
        data: (FitnessStats s) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(fitnessStatsProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: <Widget>[
              _StepsRing(stats: s),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(
                    child: StatTile(
                      icon: Icons.local_fire_department,
                      value: '${s.caloriesKcal}',
                      label: 'kcal',
                      color: FitBoxColors.red,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatTile(
                      icon: Icons.straighten,
                      value: '${s.distanceKm.toStringAsFixed(1)} km',
                      label: 'distance',
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatTile(
                      icon: Icons.timer_outlined,
                      value: '${s.activeMinutes}',
                      label: 'active min',
                      color: FitBoxColors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const SectionHeader('This week'),
              _WeeklyBars(weeklySteps: s.weeklySteps),
            ]
                .animate(interval: 70.ms)
                .fadeIn(duration: 320.ms)
                .slideY(begin: 0.12, end: 0, curve: Curves.easeOut),
          ),
        ),
      ),
    );
  }
}

class _StepsRing extends StatelessWidget {
  const _StepsRing({required this.stats});

  final FitnessStats stats;

  @override
  Widget build(BuildContext context) {
    final NumberFormat fmt = NumberFormat.decimalPattern();
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme cs = Theme.of(context).colorScheme;
    return GlassCard(
      radius: 26,
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: SizedBox(
          width: 196,
          height: 196,
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
                    width: 196,
                    height: 196,
                    child: CircularProgressIndicator(
                      value: animatedProgress,
                      strokeWidth: 14,
                      strokeCap: StrokeCap.round,
                      backgroundColor: cs.onSurface.withValues(alpha: 0.10),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          FitBoxColors.red),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(fmt.format(animatedSteps),
                          style: text.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface)),
                      Text('of ${fmt.format(stats.stepGoal)} steps',
                          style: text.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant)),
                      const SizedBox(height: 4),
                      Text('${(animatedProgress * 100).round()}%',
                          style: text.titleMedium?.copyWith(
                              color: FitBoxColors.red,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _WeeklyBars extends StatelessWidget {
  const _WeeklyBars({required this.weeklySteps});

  final List<int> weeklySteps;

  static const List<String> _days = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final int maxSteps =
        weeklySteps.isEmpty ? 1 : weeklySteps.reduce((a, b) => a > b ? a : b);
    return GlassCard(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      child: SizedBox(
        height: 132,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List<Widget>.generate(weeklySteps.length, (int i) {
            final double ratio = maxSteps == 0 ? 0 : weeklySteps[i] / maxSteps;
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
                          color: today
                              ? FitBoxColors.red
                              : cs.onSurface.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(_days[i % _days.length],
                      style:
                          TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
