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
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String title = run?.title ?? 'Central Park Loop';
    final double km = run?.distanceKm ?? 5.24;
    final double pace = run?.paceMinPerKm ?? 5.38;
    final Duration dur = run?.duration ?? const Duration(minutes: 28, seconds: 15);

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
          // Personal best banner.
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(colors: <Color>[
                FitBoxColors.red.withValues(alpha: 0.28),
                FitBoxColors.red.withValues(alpha: 0.06),
              ]),
              border: Border.all(color: FitBoxColors.red.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: <Widget>[
                const CircleAvatar(
                  backgroundColor: FitBoxColors.red,
                  child: Icon(Icons.local_fire_department, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('NEW PERSONAL BEST',
                        style: AppText.labelCaps(context)),
                    Text('+150 pts earned',
                        style: AppText.kinetic(context,
                            size: 24, color: FitBoxColors.red)),
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
          const SizedBox(height: 16),
          GlassCard(
            radius: 24,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Pace splits', style: AppText.kinetic(context, size: 22)),
                const SizedBox(height: 18),
                SizedBox(
                  height: 90,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List<Widget>.generate(5, (int i) {
                      final double h = <double>[0.6, 0.8, 0.5, 0.9, 0.7][i];
                      return Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            FractionallySizedBox(
                              heightFactor: h,
                              child: Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                decoration: BoxDecoration(
                                  color: FitBoxColors.red
                                      .withValues(alpha: 0.3 + h * 0.5),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text('${i + 1}',
                                style: AppText.labelCaps(context, size: 10)),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 10),
                Divider(color: cs.onSurface.withValues(alpha: 0.12)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text('Fastest: 4:50',
                        style: TextStyle(color: cs.onSurfaceVariant)),
                    Text('Slowest: 6:10',
                        style: TextStyle(color: cs.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
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
