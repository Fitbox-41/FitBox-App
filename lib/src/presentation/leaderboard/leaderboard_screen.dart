import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../widgets/glass.dart';

class _Entry {
  const _Entry(this.rank, this.name, this.area, {this.me = false});
  final int rank;
  final String name;
  final String area;
  final bool me;
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
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(child: _Podium(_entries[1], height: 96)),
              Expanded(child: _Podium(_entries[0], height: 124, gold: true)),
              Expanded(child: _Podium(_entries[2], height: 78)),
            ],
          ),
          const SizedBox(height: 24),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              children: <Widget>[
                for (final _Entry e in rest) _Row(e),
              ],
            ),
          ),
        ],
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
    return Column(
      children: <Widget>[
        CircleAvatar(
          radius: gold ? 30 : 24,
          backgroundColor: FitBoxColors.red.withValues(alpha: 0.2),
          child: Text(entry.name.characters.first,
              style: AppText.kinetic(context,
                  size: gold ? 22 : 18, color: FitBoxColors.red)),
        ),
        const SizedBox(height: 8),
        Text(entry.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600)),
        Text(entry.area,
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gold
                  ? const <Color>[FitBoxColors.red, FitBoxColors.redDark]
                  : <Color>[
                      cs.onSurface.withValues(alpha: 0.14),
                      cs.onSurface.withValues(alpha: 0.06),
                    ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(14)),
          ),
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 10),
          child: Text('${entry.rank}',
              style: AppText.data(context,
                  size: 24,
                  italic: true,
                  color: gold ? Colors.white : cs.onSurface)),
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
    return Container(
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
                style: AppText.data(context,
                    size: 18,
                    color: entry.me ? FitBoxColors.red : cs.onSurfaceVariant)),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 18,
            backgroundColor: cs.onSurface.withValues(alpha: 0.1),
            child: Text(entry.name.characters.first,
                style: TextStyle(color: cs.onSurface)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(entry.name,
                style: TextStyle(
                    color: cs.onSurface,
                    fontWeight:
                        entry.me ? FontWeight.w700 : FontWeight.w500)),
          ),
          Text(entry.area,
              style: TextStyle(
                  color: entry.me ? FitBoxColors.red : cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
