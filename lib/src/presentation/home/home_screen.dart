import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/fitness_stats.dart';
import '../../data/providers.dart';
import '../widgets/common.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<FitnessStats> stats = ref.watch(fitnessStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FitBox'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.notifications_none),
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: <Widget>[
              _StepsRing(stats: s),
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  Expanded(
                    child: StatTile(
                      icon: Icons.local_fire_department,
                      value: '${s.caloriesKcal}',
                      label: 'kcal',
                      color: FitBoxColors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatTile(
                      icon: Icons.straighten,
                      value: '${s.distanceKm.toStringAsFixed(1)} km',
                      label: 'distance',
                      color: FitBoxColors.greenLight,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatTile(
                      icon: Icons.timer_outlined,
                      value: '${s.activeMinutes}',
                      label: 'active min',
                      color: FitBoxColors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const SectionHeader('This week'),
              _WeeklyBars(weeklySteps: s.weeklySteps),
            ],
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: SizedBox(
          width: 190,
          height: 190,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              SizedBox(
                width: 190,
                height: 190,
                child: CircularProgressIndicator(
                  value: stats.stepProgress,
                  strokeWidth: 14,
                  strokeCap: StrokeCap.round,
                  backgroundColor:
                      Theme.of(context).colorScheme.outlineVariant,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(FitBoxColors.green),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(fmt.format(stats.steps),
                      style: text.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  Text('of ${fmt.format(stats.stepGoal)} steps',
                      style: text.bodySmall
                          ?.copyWith(color: Theme.of(context).hintColor)),
                  const SizedBox(height: 4),
                  Text('${(stats.stepProgress * 100).round()}%',
                      style: text.titleMedium?.copyWith(
                          color: FitBoxColors.orange,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ],
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
    final int maxSteps =
        weeklySteps.isEmpty ? 1 : weeklySteps.reduce((a, b) => a > b ? a : b);
    return Container(
      height: 160,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List<Widget>.generate(weeklySteps.length, (int i) {
          final double ratio = maxSteps == 0 ? 0 : weeklySteps[i] / maxSteps;
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
                        color: i == weeklySteps.length - 1
                            ? FitBoxColors.orange
                            : FitBoxColors.greenLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(_days[i % _days.length],
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          );
        }),
      ),
    );
  }
}
