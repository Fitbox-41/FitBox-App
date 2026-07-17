import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/run_activity.dart';
import '../../data/providers.dart';
import '../widgets/common.dart';
import '../widgets/glass.dart';

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<RunActivity>> runs = ref.watch(runsProvider);
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: runs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, _) => AsyncRetry(
          message: "Couldn't load your activity.",
          onRetry: () => ref.invalidate(runsProvider),
        ),
        data: (List<RunActivity> list) {
          final double totalKm =
              list.fold(0, (double a, RunActivity r) => a + r.distanceKm);
          final int totalMinutes = list.fold(
              0, (int a, RunActivity r) => a + r.duration.inMinutes);
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(runsProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text('This Month', style: AppText.kinetic(context, size: 28)),
                    _MonthChip(label: DateFormat('MMMM').format(DateTime.now())),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _MonthStat(
                        label: 'Distance',
                        value: totalKm.toStringAsFixed(0),
                        unit: 'km',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MonthStat(
                        label: 'Time',
                        value: (totalMinutes / 60).toStringAsFixed(0),
                        unit: 'h',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MonthStat(
                        label: 'Runs',
                        value: '${list.length}',
                        valueColor: FitBoxColors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const _FilterPills(),
                const SizedBox(height: 20),
                if (list.isEmpty)
                  GlassCard(
                    padding: const EdgeInsets.all(28),
                    child: Center(
                      child: Text(
                        'No runs recorded yet.\nStart a run to see it here!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    ),
                  )
                else
                  ...List<Widget>.generate(
                    list.length,
                    (int i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _RunCard(list[i])
                          .animate()
                          .fadeIn(delay: (i * 60).ms, duration: 320.ms)
                          .slideY(begin: 0.12, end: 0, curve: Curves.easeOut),
                    ),
                  ),
              ],
            ),
          );
        },
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
  final String value;
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
                  child: Text(value,
                      style: AppText.data(context,
                          size: 30, color: valueColor ?? cs.onSurface)),
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

class _RunCard extends StatelessWidget {
  const _RunCard(this.run);

  final RunActivity run;

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
      child: Row(
        children: <Widget>[
          // Route thumbnail placeholder (real map thumbnails arrive with Maps).
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
            ),
            child: Icon(Icons.map_outlined,
                color: FitBoxColors.red.withValues(alpha: 0.8), size: 30),
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
                          style: AppText.kinetic(context, size: 20)),
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
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                color: cs.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w700)),
      ],
    );
  }
}
