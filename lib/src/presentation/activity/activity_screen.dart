import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/run_activity.dart';
import '../../data/recorded_runs.dart';
import '../widgets/glass.dart';
import '../widgets/motion.dart';

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<RunActivity> list = ref.watch(recordedRunsProvider);
    final double totalKm =
        list.fold(0, (double a, RunActivity r) => a + r.distanceKm);
    final int totalMinutes =
        list.fold(0, (int a, RunActivity r) => a + r.duration.inMinutes);

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(recordedRunsProvider),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('This Month', style: AppText.kinetic(context, size: 24)),
                _MonthChip(label: DateFormat('MMMM').format(DateTime.now())),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: _MonthStat(
                    label: 'Distance',
                    value: totalKm,
                    unit: 'km',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MonthStat(
                    label: 'Time',
                    value: totalMinutes / 60,
                    unit: 'h',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MonthStat(
                    label: 'Runs',
                    value: list.length.toDouble(),
                    valueColor: FitBoxColors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const _FilterPills(),
            const SizedBox(height: 20),
            if (list.isEmpty)
              const _EmptyState()
            else
              ...List<Widget>.generate(
                list.length,
                (int i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _RunCard(
                    list[i],
                    onTap: () => context.push('/run-summary', extra: list[i]),
                  ),
                ),
              ),
          ].revealStagger(),
        ),
      ),
    );
  }
}

class _MonthChip extends StatelessWidget {
  const _MonthChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(label.toUpperCase(), style: AppText.labelCaps(context)),
          const SizedBox(width: 4),
          Icon(Icons.keyboard_arrow_down,
              size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

class _MonthStat extends StatelessWidget {
  const _MonthStat({
    required this.label,
    required this.value,
    this.unit,
    this.valueColor,
  });

  final String label;
  final double value;
  final String? unit;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return GlassCard(
      radius: 22,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label.toUpperCase(), style: AppText.labelCaps(context, size: 11)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: CountUpText(
                    value: value,
                    builder: (BuildContext c, double v) => Text(
                      v.toStringAsFixed(0),
                      style: AppText.data(context,
                          size: 30, color: valueColor ?? cs.onSurface),
                    ),
                  ),
                ),
              ),
              if (unit != null) ...<Widget>[
                const SizedBox(width: 2),
                Text(unit!,
                    style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterPills extends StatelessWidget {
  const _FilterPills();

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    Widget pill(String label, bool active) => Container(
          margin: const EdgeInsets.only(right: 10),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: active ? FitBoxColors.red : cs.onSurface.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(22),
            border: active
                ? null
                : Border.all(color: cs.onSurface.withValues(alpha: 0.12)),
            boxShadow: active
                ? <BoxShadow>[
                    BoxShadow(
                      color: FitBoxColors.red.withValues(alpha: 0.35),
                      blurRadius: 16,
                      spreadRadius: -4,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label.toUpperCase(),
            style: AppText.labelCaps(context,
                size: 11,
                color: active ? Colors.white : cs.onSurfaceVariant),
          ),
        );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          pill('All activity', true),
          pill('Runs', false),
          pill('Walks', false),
        ],
      ),
    );
  }
}

/// Shown when the athlete hasn't recorded any runs yet — an encouraging,
/// on-brand nudge rather than a bare line of grey text.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return GlassCard(
      radius: 26,
      padding: const EdgeInsets.fromLTRB(28, 36, 28, 34),
      child: Column(
        children: <Widget>[
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: <Color>[
                FitBoxColors.red.withValues(alpha: 0.28),
                FitBoxColors.red.withValues(alpha: 0.06),
              ]),
              border:
                  Border.all(color: FitBoxColors.red.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.directions_run,
                color: FitBoxColors.red, size: 40),
          ),
          const SizedBox(height: 20),
          Text('No runs yet', style: AppText.kinetic(context, size: 24)),
          const SizedBox(height: 8),
          Text(
            'Your recorded runs will show up here.\nLace up and log your first one.',
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurfaceVariant, height: 1.4),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: cs.onSurface.withValues(alpha: 0.12)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.play_arrow_rounded,
                    color: FitBoxColors.red, size: 18),
                const SizedBox(width: 6),
                Text('Start a run from Home',
                    style: AppText.labelCaps(context, size: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RunCard extends StatelessWidget {
  const _RunCard(this.run, {this.onTap});

  final RunActivity run;
  final VoidCallback? onTap;

  String get _pace {
    final double p = run.paceMinPerKm;
    final int m = p.floor();
    final int s = ((p - m) * 60).round();
    return "$m:${s.toString().padLeft(2, '0')} /km";
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return GlassCard(
      radius: 22,
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: <Widget>[
          // Leading run icon in a red-tinted rounded chip.
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  FitBoxColors.red.withValues(alpha: 0.24),
                  FitBoxColors.red.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: FitBoxColors.red.withValues(alpha: 0.28)),
            ),
            child: const Icon(Icons.directions_run,
                color: FitBoxColors.red, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(run.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.kinetic(context, size: 19)),
                    ),
                    Text(DateFormat('MMM d').format(run.date).toUpperCase(),
                        style: AppText.labelCaps(context, size: 11)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    _metric(context, 'Distance',
                        '${run.distanceKm.toStringAsFixed(1)} km'),
                    Container(
                      width: 1,
                      height: 30,
                      margin: const EdgeInsets.symmetric(horizontal: 14),
                      color: cs.onSurface.withValues(alpha: 0.12),
                    ),
                    _metric(context, 'Pace', _pace),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(BuildContext context, String label, String value) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label.toUpperCase(), style: AppText.labelCaps(context, size: 10)),
        const SizedBox(height: 3),
        Text(value,
            style: AppText.data(context, size: 16, color: cs.onSurface)),
      ],
    );
  }
}
