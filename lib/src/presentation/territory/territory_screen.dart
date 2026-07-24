import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/territory.dart';
import '../../data/territory_repository.dart';
import '../auth/auth_controller.dart';
import '../widgets/glass.dart';
import '../widgets/live_run_map.dart';

/// The shared Territory map — a full-screen live map showing EVERY user's
/// captured territory (yours red, rivals blue) plus your location. Run a loop to
/// claim the area you enclose; overlaps are taken from whoever held them.
class TerritoryScreen extends ConsumerWidget {
  const TerritoryScreen({super.key});

  String _fmtArea(double sqm) {
    if (sqm <= 0) return '0 m²';
    if (sqm < 100000) return '${sqm.round()} m²';
    return '${(sqm / 1000000).toStringAsFixed(2)} km²';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String? myId = ref.watch(authControllerProvider).user?.id;
    final AsyncValue<List<TerritoryArea>> async = ref.watch(territoriesProvider);
    final List<TerritoryArea> list =
        async.asData?.value ?? const <TerritoryArea>[];

    final double myArea = list
        .where((TerritoryArea t) => t.userId == myId)
        .fold(0.0, (double a, TerritoryArea t) => a + t.area);
    final List<TerritoryArea> ranked = <TerritoryArea>[...list]
      ..sort((TerritoryArea a, TerritoryArea b) => b.area.compareTo(a.area));
    final int myRank =
        myId == null ? 0 : ranked.indexWhere((t) => t.userId == myId) + 1;

    return Scaffold(
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: LiveRunMap(
              territories: list,
              currentUserId: myId,
              showMyLocation: true,
              interactive: true,
            ),
          ),

          // Top: title + legend + refresh.
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: <Widget>[
                  _MapPill(
                    child: Text('TERRITORY',
                        style: AppText.labelCaps(context, size: 12)),
                  ),
                  const SizedBox(width: 8),
                  const _MapPill(child: _Legend()),
                  const Spacer(),
                  _MapPill(
                    onTap: () => ref.invalidate(territoriesProvider),
                    child: Icon(Icons.refresh,
                        size: 18, color: cs.onSurface),
                  ),
                ],
              ),
            ),
          ),

          if (async.isLoading)
            const Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.only(top: 92),
                child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4)),
              ),
            ),

          // Bottom: your holdings + a run CTA (clears the floating nav pill).
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  16, 0, 16, 108 + MediaQuery.paddingOf(context).bottom),
              child: GlassCard(
                radius: 24,
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _Stat(
                            label: 'YOUR TERRITORY',
                            value: _fmtArea(myArea),
                            color: FitBoxColors.red,
                          ),
                        ),
                        Container(
                            width: 1,
                            height: 38,
                            color: cs.onSurface.withValues(alpha: 0.12)),
                        Expanded(
                          child: _Stat(
                            label: 'RANK',
                            value: myRank > 0 ? '#$myRank' : '—',
                            color: cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    GlowButton(
                      label: 'Run to claim territory',
                      icon: Icons.directions_run_rounded,
                      onPressed: () => context.push('/record-run'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A frosted control/label pill floated over the map.
class _MapPill extends StatelessWidget {
  const _MapPill({required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Brightness b = Theme.of(context).brightness;
    final Widget pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: FitBoxColors.glassFill(b),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FitBoxColors.glassStroke(b)),
      ),
      child: child,
    );
    if (onTap == null) return pill;
    return GestureDetector(onTap: onTap, child: pill);
  }
}

class _Legend extends StatelessWidget {
  const _Legend();
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _dot(FitBoxColors.red),
        const SizedBox(width: 5),
        Text('YOU', style: AppText.labelCaps(context, size: 10)),
        const SizedBox(width: 12),
        _dot(const Color(0xFF4C8DFF)),
        const SizedBox(width: 5),
        Text('RIVALS', style: AppText.labelCaps(context, size: 10)),
      ],
    );
  }

  Widget _dot(Color c) => Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle));
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(label, style: AppText.labelCaps(context, size: 10)),
        const SizedBox(height: 6),
        Text(value, style: AppText.data(context, size: 22, color: color)),
      ],
    );
  }
}
