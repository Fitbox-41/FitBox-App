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

  /// "PRIZE IN 2D 14H" — how long until this week's prize is decided.
  ///
  /// Deliberately not "resets": territory is permanent now, and only the weekly
  /// competition rolls over. Saying "reset" would suggest the land disappears.
  String? _seasonLabel(DateTime? endsAt) {
    if (endsAt == null) return null;
    final Duration d = endsAt.difference(DateTime.now());
    if (d.isNegative) return 'DECIDING…';
    if (d.inDays >= 1) return 'PRIZE IN ${d.inDays}D ${d.inHours % 24}H';
    if (d.inHours >= 1) return 'PRIZE IN ${d.inHours}H ${d.inMinutes % 60}M';
    return 'PRIZE IN ${d.inMinutes}M';
  }

  static String fmtArea(double sqm) {
    if (sqm <= 0) return '0 m²';
    if (sqm < 100000) return '${sqm.round()} m²';
    return '${(sqm / 1000000).toStringAsFixed(2)} km²';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String? myId = ref.watch(authControllerProvider).user?.id;
    final AsyncValue<TerritorySnapshot> async = ref.watch(territoriesProvider);
    final TerritorySnapshot? snap = async.asData?.value;
    final List<TerritoryArea> list = snap?.areas ?? const <TerritoryArea>[];
    final DateTime? seasonEndsAt = snap?.seasonEndsAt;

    final Iterable<TerritoryArea> mine =
        list.where((TerritoryArea t) => t.userId == myId);
    final double myArea =
        mine.fold(0.0, (double a, TerritoryArea t) => a + t.area);
    // Land you hold in separate places — every run in a new area adds one.
    final int myRegions =
        mine.fold(0, (int a, TerritoryArea t) => a + t.polygons.length);
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
              // Tapping a patch of land says who holds it and what they ran to
              // get it — otherwise the map is anonymous colour.
              onTerritoryTap: (TerritoryArea t) =>
                  _showOwner(context, t, isMine: t.userId == myId),
            ),
          ),

          // Top: view switch + legend + refresh.
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              // The switch and the refresh button are controls and keep their
              // full size; the legend is the only thing here that can give way,
              // so it gets whatever width is left. On a 360 dp phone all three
              // at natural width overflowed and the refresh button was clipped
              // off the right edge.
              child: Row(
                children: <Widget>[
                  const _ViewSwitch(),
                  const SizedBox(width: 8),
                  const Flexible(
                    child: _MapPill(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: _Legend(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
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

          // Bottom: your holdings + a run CTA. The Scaffold already reports the
          // floating nav's height as the body's bottom inset, so we only add a
          // small gap on top of it (otherwise the card floats too high).
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  16, 0, 16, 12 + MediaQuery.paddingOf(context).bottom),
              child: GlassCard(
                radius: 24,
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (_seasonLabel(seasonEndsAt) != null) ...<Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(Icons.timer_outlined,
                              size: 13,
                              color: FitBoxColors.red.withValues(alpha: 0.9)),
                          const SizedBox(width: 6),
                          Text('SEASON · ${_seasonLabel(seasonEndsAt)}',
                              style: AppText.labelCaps(context, size: 10)),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _Stat(
                            label: snap?.view == TerritoryView.week
                                ? 'CLAIMED THIS WEEK'
                                : 'YOUR TERRITORY',
                            value: fmtArea(myArea),
                            color: FitBoxColors.red,
                          ),
                        ),
                        Container(
                            width: 1,
                            height: 38,
                            color: cs.onSurface.withValues(alpha: 0.12)),
                        Expanded(
                          child: _Stat(
                            label: 'REGIONS',
                            value: '$myRegions',
                            color: cs.onSurface,
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
                    const SizedBox(height: 10),
                    // Who else is on this map. Collapsed by default so it can't
                    // crowd out the map itself.
                    _OwnersList(areas: ranked, myId: myId),
                    const SizedBox(height: 10),
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

/// Owner card for a tapped territory: who holds it, their rank, and the running
/// behind it. Everything shown comes from the server so it matches the
/// leaderboard exactly.
void _showOwner(BuildContext context, TerritoryArea t, {required bool isMine}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (BuildContext ctx) {
      final ColorScheme cs = Theme.of(ctx).colorScheme;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GlassCard(
            radius: 24,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    _OwnerAvatar(area: t, radius: 26),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(isMine ? '${t.userName} (you)' : t.userName,
                              style: AppText.kinetic(context, size: 22)),
                          Text(
                            t.rank > 0 ? 'Rank #${t.rank}' : 'Unranked',
                            style: AppText.labelCaps(context, size: 11),
                          ),
                        ],
                      ),
                    ),
                    Text(TerritoryScreen.fmtArea(t.area),
                        style: AppText.kinetic(context,
                            size: 20, color: FitBoxColors.red)),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: <Widget>[
                    Expanded(child: _MiniStat('DISTANCE', '${t.distanceKm.toStringAsFixed(1)} km')),
                    Expanded(child: _MiniStat('STEPS', _grouped(t.steps))),
                    Expanded(child: _MiniStat('RUNS', '${t.runs}')),
                    Expanded(child: _MiniStat('REGIONS', '${t.polygons.length}')),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  isMine
                      ? 'Your land stays on the map until a rival runs over it.'
                      : 'Run over this ground to take part of it.',
                  style: AppTypography.caption(size: 12, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

String _grouped(int v) =>
    v.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (Match m) => '${m[1]},');

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: AppText.labelCaps(context, size: 9)),
        const SizedBox(height: 2),
        Text(value, style: AppText.data(context, size: 16)),
      ],
    );
  }
}

/// Profile photo when the owner signed in with Google, otherwise their initial —
/// the same fallback the leaderboard uses, so nobody is a blank circle.
class _OwnerAvatar extends StatelessWidget {
  const _OwnerAvatar({required this.area, this.radius = 18});
  final TerritoryArea area;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final Color bg = FitBoxColors.red.withValues(alpha: 0.18);
    if (area.photoUrl != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bg,
        foregroundImage: NetworkImage(area.photoUrl!),
        // Falls back to the initial if the image fails to load.
        child: Text(area.initial,
            style: AppText.kinetic(context, size: radius * 0.9)),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      child:
          Text(area.initial, style: AppText.kinetic(context, size: radius * 0.9)),
    );
  }
}

/// Switches the map between the permanent record and this week's claims.
class _ViewSwitch extends ConsumerWidget {
  const _ViewSwitch();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TerritoryView view = ref.watch(territoryViewProvider);
    Widget tab(String label, TerritoryView value) {
      final bool on = view == value;
      return GestureDetector(
        onTap: () => ref.read(territoryViewProvider.notifier).show(value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: on ? FitBoxColors.red : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            style: AppText.labelCaps(context,
                size: 10,
                color: on ? Colors.white : Theme.of(context).colorScheme.onSurface),
          ),
        ),
      );
    }

    return _MapPill(
      child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
        tab('ALL TIME', TerritoryView.lifetime),
        const SizedBox(width: 4),
        tab('THIS WEEK', TerritoryView.week),
      ]),
    );
  }
}

/// Everyone holding land on the map, ranked. Collapsed by default — the owner
/// asked for a way to tell whose territory is whose without cluttering the map.
class _OwnersList extends StatelessWidget {
  const _OwnersList({required this.areas, required this.myId});
  final List<TerritoryArea> areas;
  final String? myId;

  @override
  Widget build(BuildContext context) {
    if (areas.isEmpty) return const SizedBox.shrink();
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        dense: true,
        title: Text('WHO HOLDS THIS MAP · ${areas.length}',
            style: AppText.labelCaps(context, size: 10)),
        children: areas.take(20).map((TerritoryArea t) {
          final bool me = t.userId == myId;
          return ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            leading: _OwnerAvatar(area: t, radius: 14),
            title: Text(
              me ? '${t.userName} (you)' : t.userName,
              style: AppTypography.body(
                  size: 13, color: me ? FitBoxColors.red : cs.onSurface),
            ),
            subtitle: Text(
              '${t.distanceKm.toStringAsFixed(1)} km · ${_grouped(t.steps)} steps',
              style: AppTypography.caption(size: 11, color: cs.onSurfaceVariant),
            ),
            trailing: Text('#${t.rank}  ${TerritoryScreen.fmtArea(t.area)}',
                style: AppText.labelCaps(context, size: 10)),
            onTap: () => _showOwner(context, t, isMine: me),
          );
        }).toList(),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
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
        const SizedBox(width: 10),
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
