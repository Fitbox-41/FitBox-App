import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/glass.dart';
import '../widgets/motion.dart';

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
          const _GoalCard(
              label: 'Daily steps', value: '8,000', progress: 0.62),
          const SizedBox(height: 12),
          const _GoalCard(
              label: 'Weekly distance', value: '20 km', progress: 0.34),
          const SizedBox(height: 12),
          const _GoalCard(
              label: 'Weekly runs', value: '4 runs', progress: 0.5),
          const SizedBox(height: 28),
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
              _Badge(icon: Icons.terrain, label: '10 km club', unlocked: true),
              _Badge(icon: Icons.map, label: 'Dominator', unlocked: false),
              _Badge(icon: Icons.speed, label: 'Sub-5 pace', unlocked: false),
              _Badge(
                  icon: Icons.emoji_events,
                  label: 'Champion',
                  unlocked: false),
            ],
          ),
        ].revealStagger(),
      ),
    );
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
