import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../widgets/glass.dart';
import '../widgets/motion.dart';

class _Entry {
  const _Entry(this.rank, this.name, this.area, {this.me = false});
  final int rank;
  final String name;
  final String area;
  final bool me;

  /// Numeric part of the area string ("18.4 km²" → 18.4) for CountUp.
  double get areaValue =>
      double.tryParse(area.split(' ').first) ?? 0;

  /// Unit suffix ("18.4 km²" → "km²").
  String get areaUnit => area.contains(' ') ? area.split(' ').last : '';
}

/// Medal accent tones for the podium (gold/silver/bronze), warmed toward the
/// FitBox brand so the top three read premium rather than literal metal.
Color _medal(int rank) {
  switch (rank) {
    case 1:
      return const Color(0xFFE7C15A); // gold
    case 2:
      return const Color(0xFFB8C0CC); // silver
    case 3:
      return const Color(0xFFCE8E5C); // bronze
    default:
      return FitBoxColors.red;
  }
}

/// Weekly leaderboard by territory captured. Sample standings until the
/// territory game goes live (arrives with Maps).
class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  static const List<_Entry> _entries = <_Entry>[
    _Entry(1, 'A. Mercer', '18.4 km²'),
    _Entry(2, 'J. Rivera', '15.1 km²'),
    _Entry(3, 'S. Kaur', '12.7 km²'),
    _Entry(4, 'You', '9.8 km²', me: true),
    _Entry(5, 'D. Osei', '8.2 km²'),
    _Entry(6, 'L. Rossi', '6.5 km²'),
  ];

  @override
  Widget build(BuildContext context) {
    final List<_Entry> rest = _entries.where((e) => e.rank > 3).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: <Widget>[
          Text('This week', style: AppText.labelCaps(context)),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(child: _Podium(_entries[1], height: 92)),
              Expanded(child: _Podium(_entries[0], height: 128, gold: true)),
              Expanded(child: _Podium(_entries[2], height: 74)),
            ],
          ),
          const SizedBox(height: 28),
          Text('Standings', style: AppText.labelCaps(context)),
          const SizedBox(height: 12),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(
              children: <Widget>[
                for (final _Entry e in rest) _Row(e),
              ],
            ),
          ),
        ].revealStagger(),
      ),
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
        // Medal-ringed avatar; gold gets a soft brand glow for extra emphasis.
        Container(
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              colors: <Color>[
                medal,
                medal.withValues(alpha: 0.35),
                medal,
              ],
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
            backgroundColor: gold
                ? FitBoxColors.red.withValues(alpha: 0.22)
                : cs.surface,
            child: Text(
              entry.name.characters.first,
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
        Text(entry.area, style: AppTypography.caption(color: cs.onSurfaceVariant)),
        const SizedBox(height: 10),
        // Pillar with a big rank numeral that counts up on reveal.
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
    final Color rankColor =
        entry.me ? FitBoxColors.red : cs.onSurfaceVariant;

    final Widget points = entry.me
        ? CountUpText(
            value: entry.areaValue,
            builder: (BuildContext context, double v) => Text(
              '${v.toStringAsFixed(1)} ${entry.areaUnit}',
              style: AppText.data(context, size: 17, color: FitBoxColors.red),
            ),
          )
        : Text(entry.area,
            style: AppText.data(context, size: 16, color: cs.onSurfaceVariant));

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
                entry.name.characters.first,
                style: AppText.kinetic(context,
                    size: 15,
                    color: entry.me ? FitBoxColors.red : cs.onSurface),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(entry.name,
                  style: AppTypography.title(
                    size: 15,
                    color: entry.me ? FitBoxColors.red : cs.onSurface,
                  )),
            ),
            points,
          ],
        ),
      ),
    );
  }
}
