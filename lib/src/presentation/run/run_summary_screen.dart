import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/run_activity.dart';
import '../../data/models/run_result.dart';
import '../../data/recorded_runs.dart';
import '../widgets/glass.dart';
import '../widgets/live_run_map.dart';
import '../widgets/map_placeholder.dart';
import '../widgets/motion.dart';
import 'share_run_sheet.dart';

/// Post-run summary — the celebratory moment. Hero headline + framed route +
/// headline metrics, with share + delete actions.
///
/// Opened immediately after a run finishes, before the upload completes: [sync]
/// is that in-flight upload, and the territory banner resolves itself when it
/// lands. Leaving the screen after a run goes to History, where the saved run
/// is waiting at the top.
class RunSummaryScreen extends ConsumerWidget {
  const RunSummaryScreen({
    super.key,
    this.run,
    this.claimedAreaSqm,
    this.sync,
  });

  final RunActivity? run;

  /// Territory area (sqm) already known for this run, if any.
  final double? claimedAreaSqm;

  /// The in-flight upload for a just-finished run (null when reopening a past
  /// run from History).
  final Future<RunSyncResult?>? sync;

  bool get _justFinished => sync != null;

  String _pace(double p) {
    final int m = p.floor();
    final int s = ((p - m) * 60).round();
    return "$m:${s.toString().padLeft(2, '0')}";
  }

  String _duration(double totalSeconds) {
    final int s = totalSeconds.round();
    return '${s ~/ 60}m ${s % 60}s';
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, RunActivity r) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Delete run?'),
        content: const Text('This removes the run from your history.'),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: FitBoxColors.debit),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(recordedRunsProvider.notifier).removeRun(r.id);
      if (context.mounted) context.go('/home');
    }
  }

  /// Shell for the territory banner so its three states (claiming / claimed /
  /// nothing claimed) share one look.
  Widget _banner(
    BuildContext context, {
    required Widget leading,
    required String label,
    required Widget value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(colors: <Color>[
          color.withValues(alpha: 0.26),
          color.withValues(alpha: 0.06),
        ]),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: <Widget>[
          leading,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label, style: AppText.labelCaps(context)),
                value,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _territoryClaimed(BuildContext context, double sqm) => _banner(
        context,
        color: FitBoxColors.red,
        leading: const CircleAvatar(
          backgroundColor: FitBoxColors.red,
          child: Icon(Icons.flag_rounded, color: Colors.white),
        ),
        label: 'TERRITORY CLAIMED',
        value: CountUpText(
          value: sqm,
          builder: (BuildContext c, double v) => Text(
            '+${v < 100000 ? '${v.round()} m²' : '${(v / 1e6).toStringAsFixed(2)} km²'}',
            style: AppText.kinetic(context, size: 24, color: FitBoxColors.red),
          ),
        ),
      );

  /// The upload is still in flight — the run is already saved locally.
  Widget _territoryPending(BuildContext context) => _banner(
        context,
        color: FitBoxColors.red,
        leading: const CircleAvatar(
          backgroundColor: FitBoxColors.red,
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
                strokeWidth: 2.2, color: Colors.white),
          ),
        ),
        label: 'TERRITORY',
        value: Text('Claiming your land…',
            style: AppText.kinetic(context, size: 20, color: FitBoxColors.red)),
      );

  /// Nothing was claimed — say why instead of failing silently.
  Widget _territoryNone(BuildContext context, String message) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return _banner(
      context,
      color: cs.onSurface,
      leading: CircleAvatar(
        backgroundColor: cs.onSurface.withValues(alpha: 0.18),
        child: Icon(Icons.flag_outlined, color: cs.onSurfaceVariant),
      ),
      label: 'NO TERRITORY CLAIMED',
      value: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(message,
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
      ),
    );
  }

  /// Resolves the in-flight upload into the right banner.
  Widget _territorySection(BuildContext context) {
    if (!_justFinished) {
      final double sqm = claimedAreaSqm ?? 0;
      return sqm > 0
          ? _territoryClaimed(context, sqm)
          : const SizedBox.shrink();
    }
    return FutureBuilder<RunSyncResult?>(
      future: sync,
      builder: (BuildContext c, AsyncSnapshot<RunSyncResult?> snap) {
        if (snap.connectionState != ConnectionState.done) {
          return _territoryPending(c);
        }
        final RunSyncResult? r = snap.data;
        if (r == null) {
          return _territoryNone(
              c, 'Saved on your phone. We\'ll claim your land when you\'re back online.');
        }
        if (r.claimedAreaSqm > 0) return _territoryClaimed(c, r.claimedAreaSqm);
        return _territoryNone(
            c, r.territoryMessage ?? 'This run didn\'t cover enough ground to claim land.');
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String title = run?.title ?? 'Central Park Loop';
    final double km = run?.distanceKm ?? 5.24;
    final double pace = run?.paceMinPerKm ?? 5.38;
    final Duration dur = run?.duration ?? const Duration(minutes: 28, seconds: 15);
    final int steps = run?.steps ?? 0;
    final int calories = run?.caloriesKcal ?? 310;
    final bool hasRoute = (run?.route.length ?? 0) >= 2;

    // After finishing a run, every way out of this screen (back button, gesture,
    // Done) goes to History with the new run at the top — that's where the user
    // expects to land once the run is saved.
    return PopScope(
      canPop: !_justFinished,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (!didPop && context.mounted) context.go('/activity');
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Run summary'),
        leading: _justFinished
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back to history',
                onPressed: () => context.go('/activity'),
              )
            : null,
      ),
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
          const SizedBox(height: 12),
          _territorySection(context),
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
            onPressed: run == null
                ? null
                : () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ShareRunSheet(run: run!),
                      ),
                    ),
          ),
          if (_justFinished) ...<Widget>[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.go('/activity'),
              icon: const Icon(Icons.list_alt_rounded),
              label: const Text('Done — see my runs'),
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: run == null
                ? null
                : () => _confirmDelete(context, ref, run!),
            style: OutlinedButton.styleFrom(foregroundColor: FitBoxColors.debit),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete run'),
          ),
        ].revealStagger(),
      ),
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
