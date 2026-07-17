import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../widgets/glass.dart';

class _Note {
  const _Note(this.icon, this.color, this.title, this.body, this.time);
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final String time;
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static const List<_Note> _notes = <_Note>[
    _Note(Icons.local_fire_department, FitBoxColors.red, 'Daily goal reached',
        'You hit 8,000 steps — +10 pts credited.', '2h ago'),
    _Note(Icons.map, FitBoxColors.credit, 'Territory captured',
        'You claimed a new zone in SoHo. +150 pts.', 'Yesterday'),
    _Note(Icons.warning_amber, FitBoxColors.debit, "You've been overtaken",
        'J. Rivera took the lead in Covent Garden.', 'Yesterday'),
    _Note(Icons.emoji_events, FitBoxColors.red, 'Weekly results',
        'You finished #4 this week. Keep pushing!', '3d ago'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        itemCount: _notes.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (BuildContext context, int i) {
          final _Note n = _notes[i];
          final ColorScheme cs = Theme.of(context).colorScheme;
          return GlassCard(
            radius: 20,
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: n.color.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(n.icon, color: n.color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(n.title,
                                style: TextStyle(
                                    color: cs.onSurface,
                                    fontWeight: FontWeight.w700)),
                          ),
                          Text(n.time,
                              style: AppText.labelCaps(context, size: 10)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(n.body,
                          style: TextStyle(
                              color: cs.onSurfaceVariant, fontSize: 13)),
                    ],
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
