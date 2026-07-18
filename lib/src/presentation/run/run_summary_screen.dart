import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/run_activity.dart';
import '../widgets/glass.dart';
import '../widgets/map_placeholder.dart';

/// Post-run summary. Route thumbnail + headline metrics + pace splits. The real
/// route map arrives with the Maps key.
class RunSummaryScreen extends StatelessWidget {
  const RunSummaryScreen({super.key, this.run});

  final RunActivity? run;

  String _pace(double p) {
    final int m = p.floor();
    final int s = ((p - m) * 60).round();
    return "$m:${s.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final String title = run?.title ?? 'Central Park Loop';
    final double km = run?.distanceKm ?? 5.24;
    final double pace = run?.paceMinPerKm ?? 5.38;
    final Duration dur = run?.duration ?? const Duration(minutes: 28, seconds: 15);
    final int steps = run?.steps ?? 0;
    final int calories = run?.caloriesKcal ?? 310;

    return Scaffold(
      appBar: AppBar(title: const Text('Run summary')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: <Widget>[
          // Route map card.
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              height: 200,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  const MapPlaceholder(showBadge: false),
                  Positioned(
                    left: 14,
                    bottom: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(title.toUpperCase(),
                          style: AppText.labelCaps(context, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Run saved banner (honest — real steps).
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(colors: <Color>[
                FitBoxColors.credit.withValues(alpha: 0.24),
                FitBoxColors.credit.withValues(alpha: 0.05),
              ]),
              border:
                  Border.all(color: FitBoxColors.credit.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: <Widget>[
                const CircleAvatar(
                  backgroundColor: FitBoxColors.credit,
                  child: Icon(Icons.check, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('RUN SAVED', style: AppText.labelCaps(context)),
                    Text('$steps steps',
                        style: AppText.kinetic(context,
                            size: 24, color: FitBoxColors.credit)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                  child: _StatCard(
                      icon: Icons.straighten,
                      label: 'Distance',
                      value: km.toStringAsFixed(2),
                      unit: 'kilometers')),
              const SizedBox(width: 12),
              Expanded(
                  child: _StatCard(
                      icon: Icons.timer_outlined,
                      label: 'Avg pace',
                      value: _pace(pace),
                      unit: '/ km')),
            ],
          ),
          const SizedBox(height: 12),
          _StatCard(
            icon: Icons.schedule,
            label: 'Duration',
            value: '${dur.inMinutes}m ${(dur.inSeconds % 60)}s',
            unit: '',
            wide: true,
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                  child: _StatCard(
                      icon: Icons.directions_walk,
                      label: 'Steps',
                      value: '$steps',
                      unit: '')),
              const SizedBox(width: 12),
              Expanded(
                  child: _StatCard(
                      icon: Icons.local_fire_department,
                      label: 'Calories',
                      value: '$calories',
                      unit: 'kcal')),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.bookmark_border),
                  label: const Text('Save run'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GlowButton(
                  label: 'Share',
                  icon: Icons.ios_share,
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    this.wide = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return GlassCard(
      radius: 22,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(label.toUpperCase(), style: AppText.labelCaps(context)),
              Icon(icon, size: 16, color: cs.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Text(value, style: AppText.data(context, size: wide ? 40 : 34)),
              if (unit.isNotEmpty) ...<Widget>[
                const SizedBox(width: 6),
                Text(unit,
                    style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
