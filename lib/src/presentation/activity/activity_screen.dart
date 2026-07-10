import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/run_activity.dart';
import '../../data/providers.dart';
import '../widgets/common.dart';

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<RunActivity>> runs = ref.watch(runsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Activity')),
      body: runs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, _) => AsyncRetry(
          message: "Couldn't load your activity.",
          onRetry: () => ref.invalidate(runsProvider),
        ),
        data: (List<RunActivity> list) {
          if (list.isEmpty) {
            return const Center(child: Text('No runs recorded yet.'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(runsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (BuildContext context, int i) => _RunCard(list[i]),
            ),
          );
        },
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
    return "$m'${s.toString().padLeft(2, '0')}\"/km";
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const CircleAvatar(
                backgroundColor: FitBoxColors.red,
                child: Icon(Icons.directions_run, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(run.title,
                        style:
                            text.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    Text(DateFormat('EEE d MMM, h:mm a').format(run.date),
                        style: text.bodySmall
                            ?.copyWith(color: Theme.of(context).hintColor)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              _metric(context, '${run.distanceKm.toStringAsFixed(1)} km', 'distance'),
              _metric(context, _duration(run.duration), 'time'),
              _metric(context, _pace, 'pace'),
              _metric(context, '${run.caloriesKcal}', 'kcal'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(BuildContext context, String value, String label) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      children: <Widget>[
        Text(value, style: text.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        Text(label,
            style: text.bodySmall?.copyWith(color: Theme.of(context).hintColor)),
      ],
    );
  }

  static String _duration(Duration d) {
    final int m = d.inMinutes;
    final int s = d.inSeconds % 60;
    return "${m}m ${s.toString().padLeft(2, '0')}s";
  }
}
