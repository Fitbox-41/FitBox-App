import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../data/recorded_runs.dart';
import '../../data/run_session.dart';
import '../widgets/glass.dart';
import '../widgets/map_placeholder.dart';

/// Live run recording. A per-second timer + the device step sensor drive the
/// metrics; GPS + the live map arrive with the Maps key. Everything shown here
/// is recorded in-app by the user — never synced from a health app.
class RecordRunScreen extends ConsumerStatefulWidget {
  const RecordRunScreen({super.key});

  @override
  ConsumerState<RecordRunScreen> createState() => _RecordRunScreenState();
}

class _RecordRunScreenState extends ConsumerState<RecordRunScreen> {
  int? _countdown = 3; // 3-2-1 before the session starts
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (!mounted) return;
      final int next = (_countdown ?? 1) - 1;
      if (next <= 0) {
        t.cancel();
        setState(() => _countdown = null);
        HapticFeedback.heavyImpact();
        ref.read(runSessionProvider.notifier).start();
      } else {
        setState(() => _countdown = next);
        HapticFeedback.selectionClick();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _fmt(Duration d) {
    final int m = d.inMinutes % 60;
    final int s = d.inSeconds % 60;
    final String mm = m.toString().padLeft(2, '0');
    final String ss = s.toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:$mm:$ss' : '$mm:$ss';
  }

  String _pace(double p) {
    if (p <= 0) return "0'00";
    final int m = p.floor();
    final int s = ((p - m) * 60).round();
    return "$m'${s.toString().padLeft(2, '0')}";
  }

  Future<void> _stop() async {
    ref.read(runSessionProvider.notifier).pause();
    HapticFeedback.mediumImpact();
    final bool? save = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Finish run?'),
        content: const Text('Save this run to your history, or discard it?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Discard'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (save == null) {
      // Dismissed → keep recording (resume).
      ref.read(runSessionProvider.notifier).resume();
      return;
    }
    if (save) {
      final run = ref.read(runSessionProvider.notifier).finish();
      await ref.read(recordedRunsProvider.notifier).addRun(run);
      if (mounted) context.pushReplacement('/run-summary', extra: run);
    } else {
      ref.read(runSessionProvider.notifier).discard();
      if (mounted) context.pop();
    }
  }

  void _close() {
    ref.read(runSessionProvider.notifier).discard();
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final RunSession s = ref.watch(runSessionProvider);
    final bool paused = s.status == RunStatus.paused;

    return Scaffold(
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: MapPlaceholder(showBadge: false)),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 10,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.circle,
                          color: paused ? Colors.amber : FitBoxColors.credit,
                          size: 10),
                      const SizedBox(width: 8),
                      Text(paused ? 'PAUSED' : 'RECORDING',
                          style: AppText.labelCaps(context,
                              size: 11, color: Colors.white)),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: _close,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GlassCard(
                radius: 28,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text('TOTAL TIME', style: AppText.labelCaps(context)),
                    const SizedBox(height: 6),
                    Text(_fmt(s.elapsed),
                        style: AppText.data(context, size: 56, italic: true)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Icon(Icons.directions_walk,
                            size: 16, color: FitBoxColors.credit),
                        const SizedBox(width: 6),
                        Text('${s.steps} steps',
                            style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: <Widget>[
                        _metric(context, 'Distance',
                            s.distanceKm.toStringAsFixed(2), 'km'),
                        _sep(cs),
                        _metric(context, 'Avg pace', _pace(s.paceMinPerKm),
                            '/km'),
                        _sep(cs),
                        _metric(context, 'Calories', '${s.calories}', 'kcal'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        _circleBtn(
                          context,
                          paused ? Icons.play_arrow : Icons.pause,
                          false,
                          () => paused
                              ? ref.read(runSessionProvider.notifier).resume()
                              : ref.read(runSessionProvider.notifier).pause(),
                        ),
                        _circleBtn(context, Icons.stop, true, _stop),
                        _circleBtn(context, Icons.layers_outlined, false, () {}),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_countdown != null)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.75),
                child: Center(
                  child: Text('$_countdown',
                      key: ValueKey<int>(_countdown!),
                      style: AppText.data(context,
                              size: 140, italic: true, color: Colors.white)
                          .copyWith(fontWeight: FontWeight.w800)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sep(ColorScheme cs) => Container(
      width: 1, height: 34, color: cs.onSurface.withValues(alpha: 0.12));

  Widget _metric(
      BuildContext context, String label, String value, String unit) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        children: <Widget>[
          Text(label.toUpperCase(), style: AppText.labelCaps(context, size: 10)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Text(value,
                  style: AppText.data(context, size: 22, italic: true)),
              const SizedBox(width: 2),
              Text(unit,
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _circleBtn(
      BuildContext context, IconData icon, bool primary, VoidCallback onTap) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: primary ? 76 : 60,
        height: primary ? 76 : 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              primary ? FitBoxColors.red : cs.onSurface.withValues(alpha: 0.08),
          border: primary
              ? null
              : Border.all(color: cs.onSurface.withValues(alpha: 0.18)),
          boxShadow: primary
              ? <BoxShadow>[
                  BoxShadow(
                    color: FitBoxColors.red.withValues(alpha: 0.4),
                    blurRadius: 22,
                    spreadRadius: -3,
                  ),
                ]
              : null,
        ),
        child: Icon(icon,
            color: primary ? Colors.white : cs.onSurface,
            size: primary ? 32 : 26),
      ),
    );
  }
}
