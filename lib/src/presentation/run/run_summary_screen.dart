import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/run_activity.dart';
import '../widgets/glass.dart';
import '../widgets/live_run_map.dart';
import '../widgets/map_placeholder.dart';
import '../widgets/motion.dart';

/// Post-run summary — the celebratory moment. Hero headline + framed route +
/// headline metrics. The real route map arrives with the Maps key.
class RunSummaryScreen extends StatelessWidget {
  const RunSummaryScreen({super.key, this.run});

  final RunActivity? run;

  String _pace(double p) {
    final int m = p.floor();
    final int s = ((p - m) * 60).round();
    return "$m:${s.toString().padLeft(2, '0')}";
  }

  String _duration(double totalSeconds) {
    final int s = totalSeconds.round();
    return '${s ~/ 60}m ${s % 60}s';
  }

  @override
  Widget build(BuildContext context) {
    final String title = run?.title ?? 'Central Park Loop';
    final double km = run?.distanceKm ?? 5.24;
    final double pace = run?.paceMinPerKm ?? 5.38;
    final Duration dur = run?.duration ?? const Duration(minutes: 28, seconds: 15);
    final int steps = run?.steps ?? 0;
    final int calories = run?.caloriesKcal ?? 310;
    final bool hasRoute = (run?.route.length ?? 0) >= 2;

    return Scaffold(
      appBar: AppBar(title: const Text('Run summary')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            20, 8, 20, 24 + MediaQuery.paddingOf(context).bottom),
        children: <Widget>[
          // Celebratory hero header.
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(Icons.emoji_events,
                      color: FitBoxColors.red, size: 18),
                  const SizedBox(width: 8),
                  Text('GREAT RUN',
                      style: AppText.labelCaps(context,
                          size: 13, color: FitBoxColors.red)),
                ],
              ),
              const SizedBox(height: 6),
              Text(title, style: AppText.kinetic(context, size: 26)),
            ],
          ),
          const SizedBox(height: 18),
          // Route map framed in a rounded glass container.
          GlassCard(
            radius: 26,
            padding: const EdgeInsets.all(6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: 196,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    if (hasRoute)
                      LiveRunMap(
                        route: run!.route,
                        follow: false,
                        interactive: false,
                        showMyLocation: false,
                      )
                    else
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
                            style:
                                AppText.labelCaps(context, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
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
                    CountUpText(
                      value: steps.toDouble(),
                      builder: (BuildContext c, double v) => Text(
                        '${v.round()} steps',
                        style: AppText.kinetic(context,
                            size: 24, color: FitBoxColors.credit),
                      ),
                    ),
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
                  value: km,
                  format: (double v) => v.toStringAsFixed(2),
                  unit: 'kilometers',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.timer_outlined,
                  label: 'Avg pace',
                  value: pace,
                  format: _pace,
                  unit: '/ km',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _StatCard(
            icon: Icons.schedule,
            label: 'Duration',
            value: dur.inSeconds.toDouble(),
            format: _duration,
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
                  value: steps.toDouble(),
                  format: (double v) => '${v.round()}',
                  unit: '',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.local_fire_department,
                  label: 'Calories',
                  value: calories.toDouble(),
                  format: (double v) => '${v.round()}',
                  unit: 'kcal',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Primary action, prominent.
          GlowButton(
            label: 'Share',
            icon: Icons.ios_share,
            onPressed: () {},
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.bookmark_border),
            label: const Text('Save run'),
          ),
        ].revealStagger(),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.format,
    required this.unit,
    this.wide = false,
  });

  final IconData icon;
  final String label;
  final double value;
  final String Function(double) format;
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
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: CountUpText(
                    value: value,
                    builder: (BuildContext c, double v) => Text(
                      format(v),
                      style: AppText.data(context, size: wide ? 40 : 34),
                    ),
                  ),
                ),
              ),
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
