import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/glass.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Goals')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: <Widget>[
          const SectionHeader('Targets'),
          GlassCard(
            radius: 24,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: const <Widget>[
                _GoalRow(
                    label: 'Daily steps', value: '8,000', progress: 0.62),
                SizedBox(height: 20),
                _GoalRow(
                    label: 'Weekly distance',
                    value: '20 km',
                    progress: 0.34),
                SizedBox(height: 20),
                _GoalRow(
                    label: 'Weekly runs', value: '4 runs', progress: 0.5),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader('Achievements'),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: const <Widget>[
              _Badge(icon: Icons.bolt, label: 'First run', unlocked: true),
              _Badge(
                  icon: Icons.local_fire_department,
                  label: '5-day streak',
                  unlocked: true),
              _Badge(
                  icon: Icons.terrain, label: '10 km club', unlocked: true),
              _Badge(icon: Icons.map, label: 'Dominator', unlocked: false),
              _Badge(
                  icon: Icons.speed, label: 'Sub-5 pace', unlocked: false),
              _Badge(
                  icon: Icons.emoji_events,
                  label: 'Champion',
                  unlocked: false),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow(
      {required this.label, required this.value, required this.progress});

  final String label;
  final String value;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Row(
      children: <Widget>[
        SizedBox(
          width: 54,
          height: 54,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 6,
                strokeCap: StrokeCap.round,
                backgroundColor: cs.onSurface.withValues(alpha: 0.1),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(FitBoxColors.red),
              ),
              Text('${(progress * 100).round()}%',
                  style: AppText.data(context, size: 12)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(label,
                  style: TextStyle(
                      color: cs.onSurface, fontWeight: FontWeight.w600)),
              Text(value,
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
            ],
          ),
        ),
        Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
      ],
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon,
              size: 30,
              color: unlocked
                  ? FitBoxColors.red
                  : cs.onSurface.withValues(alpha: 0.25)),
          const SizedBox(height: 8),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11,
                  color: unlocked ? cs.onSurface : cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}
