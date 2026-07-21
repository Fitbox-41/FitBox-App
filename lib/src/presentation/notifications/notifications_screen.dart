import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../widgets/glass.dart';
import '../widgets/motion.dart';

class _Note {
  const _Note(
    this.icon,
    this.color,
    this.title,
    this.body,
    this.time, {
    this.unread = false,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final String time;
  final bool unread;
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static const List<_Note> _notes = <_Note>[
    _Note(Icons.local_fire_department, FitBoxColors.red, 'Daily goal reached',
        'You hit 8,000 steps — +10 pts credited.', '2h ago',
        unread: true),
    _Note(Icons.map, FitBoxColors.credit, 'Territory captured',
        'You claimed a new zone in SoHo. +150 pts.', 'Yesterday',
        unread: true),
    _Note(Icons.warning_amber, FitBoxColors.debit, "You've been overtaken",
        'J. Rivera took the lead in Covent Garden.', 'Yesterday'),
    _Note(Icons.emoji_events, FitBoxColors.red, 'Weekly results',
        'You finished #4 this week. Keep pushing!', '3d ago'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: _notes.isEmpty
          ? const _EmptyState()
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: <Widget>[
                for (int i = 0; i < _notes.length; i++)
                  Padding(
                    padding: EdgeInsets.only(
                        bottom: i == _notes.length - 1 ? 0 : 12),
                    child: _NoteRow(note: _notes[i]),
                  ),
              ].revealStagger(),
            ),
    );
  }
}

/// A single notification presented as a frosted glass row: a category-tinted
/// rounded icon chip, an Oswald title, supporting body, a timestamp, plus a red
/// unread dot for items that have not been seen.
class _NoteRow extends StatelessWidget {
  const _NoteRow({required this.note});

  final _Note note;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return GlassCard(
      radius: 20,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: note.color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(note.icon, color: note.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    if (note.unread) ...<Widget>[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: FitBoxColors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        note.title,
                        style: AppTypography.title(
                            size: 16, color: cs.onSurface),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(note.time,
                        style: AppText.labelCaps(context, size: 10)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(note.body,
                    style: AppTypography.caption(
                        size: 13, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tasteful empty state shown when there are no notifications.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: FitBoxColors.red.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_none,
                  color: FitBoxColors.red, size: 38),
            ),
            const SizedBox(height: 20),
            Text("You're all caught up",
                style: AppText.kinetic(context, size: 22)),
            const SizedBox(height: 8),
            Text(
              'Alerts about your goals, territory and rivals will show up here.',
              textAlign: TextAlign.center,
              style: AppTypography.caption(
                  size: 13, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ).reveal(),
    );
  }
}
