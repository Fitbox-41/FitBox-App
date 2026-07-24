import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/territory.dart';
import '../../data/territory_repository.dart';
import '../auth/auth_controller.dart';
import '../widgets/common.dart';
import '../widgets/glass.dart';
import '../widgets/motion.dart';
import '../widgets/shimmer.dart';

class _Entry {
  const _Entry(this.rank, this.name, this.sqm, {this.me = false});
  final int rank;
  final String name;
  final double sqm;
  final bool me;

  String get area => sqm < 100000
      ? '${sqm.round()} m²'
      : '${(sqm / 1000000).toStringAsFixed(2)} km²';
}

/// Medal accent tones for the podium (gold/silver/bronze), warmed toward the
/// FitBox brand so the top three read premium rather than literal metal.
Color _medal(int rank) {
  switch (rank) {
    case 1:
      return const Color(0xFFE7C15A);
    case 2:
      return const Color(0xFFB8C0CC);
    case 3:
      return const Color(0xFFCE8E5C);
    default:
      return FitBoxColors.red;
  }
}

/// Live leaderboard ranked by territory captured (area), from the shared map.
class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? myId = ref.watch(authControllerProvider).user?.id;
    final AsyncValue<List<TerritoryArea>> async =
        ref.watch(territoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(territoriesProvider),
        child: async.when(
          loading: () => const SkeletonList(count: 6),
          error: (Object e, _) => ListView(
            children: <Widget>[
              const SizedBox(height: 140),
              AsyncRetry(
                message: "Couldn't load the leaderboard.",
                onRetry: () => ref.invalidate(territoriesProvider),
              ),
            ],
          ),
          data: (List<TerritoryArea> list) {
            final List<TerritoryArea> sorted = <TerritoryArea>[...list]
              ..sort((TerritoryArea a, TerritoryArea b) =>
                  b.area.compareTo(a.area));
            final List<_Entry> entries = <_Entry>[
              for (int i = 0; i < sorted.length; i++)
                _Entry(i + 1, sorted[i].userName, sorted[i].area,
                    me: sorted[i].userId == myId),
            ];

            if (entries.isEmpty) return const _EmptyBoard();

            final List<_Entry> top = entries.take(3).toList();
            final List<_Entry> rest = entries.skip(3).toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              children: <Widget>[
                Text('Ranked by territory', style: AppText.labelCaps(context)),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Expanded(
                      child: top.length > 1
                          ? _Podium(top[1], height: 92)
                          : const SizedBox.shrink(),
                    ),
                    Expanded(child: _Podium(top[0], height: 128, gold: true)),
                    Expanded(
                      child: top.length > 2
                          ? _Podium(top[2], height: 74)
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
                if (rest.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 28),
                  Text('Standings', style: AppText.labelCaps(context)),
                  const SizedBox(height: 12),
                  GlassCard(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Column(
                      children: <Widget>[
                        for (final _Entry e in rest) _Row(e),
                      ],
                    ),
                  ),
                ],
              ].revealStagger(),
            );
          },
        ),
      ),
    );
  }
}

class _EmptyBoard extends StatelessWidget {
  const _EmptyBoard();

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 100, 24, 24),
      children: <Widget>[
        Center(
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: <Color>[
                FitBoxColors.red.withValues(alpha: 0.28),
                FitBoxColors.red.withValues(alpha: 0.06),
              ]),
              border: Border.all(color: FitBoxColors.red.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.flag_rounded,
                color: FitBoxColors.red, size: 40),
          ),
        ),
        const SizedBox(height: 20),
        Text('No territory claimed yet',
            textAlign: TextAlign.center, style: AppText.kinetic(context, size: 22)),
        const SizedBox(height: 8),
        Text('Run a loop around an area to claim your first territory and top '
            'the board.',
            textAlign: TextAlign.center,
            style: AppTypography.body(size: 14, color: cs.onSurfaceVariant)),
      ],
    );
  }
}

class _Podium extends StatelessWidget {
  const _Podium(this.entry, {required this.height, this.gold = false});

  final _Entry entry;
  final double height;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color medal = _medal(entry.rank);
    final double avatarRadius = gold ? 32 : 25;

    return Column(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              colors: <Color>[medal, medal.withValues(alpha: 0.35), medal],
            ),
            boxShadow: gold
                ? <BoxShadow>[
                    BoxShadow(
                      color: FitBoxColors.red.withValues(alpha: 0.35),
                      blurRadius: 20,
                      spreadRadius: -2,
                    ),
                  ]
                : null,
          ),
          child: CircleAvatar(
            radius: avatarRadius,
            backgroundColor:
                gold ? FitBoxColors.red.withValues(alpha: 0.22) : cs.surface,
            child: Text(
              entry.name.characters.first.toUpperCase(),
              style: AppText.kinetic(context,
                  size: gold ? 24 : 19,
                  color: gold ? FitBoxColors.red : medal),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(entry.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.title(size: 14, color: cs.onSurface)),
        const SizedBox(height: 2),
        Text(entry.area,
            style: AppTypography.caption(color: cs.onSurfaceVariant)),
        const SizedBox(height: 10),
        Container(
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gold
                  ? const <Color>[FitBoxColors.red, FitBoxColors.redDark]
                  : <Color>[
                      medal.withValues(alpha: 0.28),
                      medal.withValues(alpha: 0.10),
                    ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border.all(
              color: (gold ? FitBoxColors.red : medal).withValues(alpha: 0.35),
            ),
          ),
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 12),
          child: CountUpText(
            value: entry.rank.toDouble(),
            duration: const Duration(milliseconds: 700),
            builder: (BuildContext context, double v) => Text(
              '${v.round()}',
              style: AppText.data(context,
                  size: gold ? 30 : 24,
                  color: gold ? Colors.white : cs.onSurface),
            ),
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.entry);

  final _Entry entry;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color rankColor = entry.me ? FitBoxColors.red : cs.onSurfaceVariant;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => HapticFeedback.selectionClick(),
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.expoOut,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: entry.me ? FitBoxColors.red.withValues(alpha: 0.16) : null,
          borderRadius: BorderRadius.circular(16),
          border: entry.me
              ? Border.all(color: FitBoxColors.red.withValues(alpha: 0.4))
              : null,
        ),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 28,
              child: Text('${entry.rank}',
                  style: AppText.data(context, size: 18, color: rankColor)),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 18,
              backgroundColor: entry.me
                  ? FitBoxColors.red.withValues(alpha: 0.25)
                  : cs.onSurface.withValues(alpha: 0.1),
              child: Text(
                entry.name.characters.first.toUpperCase(),
                style: AppText.kinetic(context,
                    size: 15,
                    color: entry.me ? FitBoxColors.red : cs.onSurface),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.title(
                    size: 15,
                    color: entry.me ? FitBoxColors.red : cs.onSurface,
                  )),
            ),
            Text(entry.area,
                style: AppText.data(context,
                    size: 16,
                    color: entry.me ? FitBoxColors.red : cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
