import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/notifications_repository.dart';
import '../auth/auth_controller.dart';
import '../widgets/common.dart';
import '../widgets/glass.dart';
import '../widgets/guest_gate.dart';
import '../widgets/motion.dart';

/// The user's real notification history, written server-side whenever an event
/// is pushed — so it's complete even if push is off or the banner was missed.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _markedRead = false;

  /// Opening the screen is what "seeing" them means, so clear the unread state
  /// once the list has actually loaded — but only once per visit.
  void _markReadOnce(int unread) {
    if (_markedRead || unread == 0) return;
    _markedRead = true;
    ref
        .read(notificationsRepositoryProvider)
        .markRead()
        .then((_) => ref.invalidate(notificationsProvider))
        .catchError((_) {/* not fatal — they stay unread and retry next time */});
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(guestModeProvider)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const GuestGate(
          icon: Icons.notifications_none,
          title: 'Your alerts live here',
          message:
              'Sign in to get alerts about your territory, rivals and weekly results.',
        ),
      );
    }

    final AsyncValue<NotificationsData> async =
        ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(notificationsProvider),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object e, StackTrace _) => AsyncRetry(
            message: 'Could not load notifications.',
            onRetry: () => ref.invalidate(notificationsProvider),
          ),
          data: (NotificationsData d) {
            _markReadOnce(d.unread);
            if (d.items.isEmpty) {
              return ListView(
                children: const <Widget>[
                  SizedBox(height: 120),
                  _EmptyState(),
                ],
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: <Widget>[
                for (int i = 0; i < d.items.length; i++)
                  Padding(
                    padding: EdgeInsets.only(
                        bottom: i == d.items.length - 1 ? 0 : 12),
                    child: _NoteRow(note: d.items[i]),
                  ),
              ].revealStagger(),
            );
          },
        ),
      ),
    );
  }
}

/// Category styling for a notification type.
({IconData icon, Color color}) _styleFor(String type) {
  switch (type) {
    case 'territory':
      return (icon: Icons.map, color: FitBoxColors.credit);
    case 'season':
      return (icon: Icons.emoji_events, color: FitBoxColors.red);
    case 'challenge':
      return (icon: Icons.local_fire_department, color: FitBoxColors.red);
    case 'wallet':
      return (icon: Icons.account_balance_wallet, color: FitBoxColors.credit);
    default:
      return (icon: Icons.notifications, color: FitBoxColors.red);
  }
}

/// A single notification presented as a frosted glass row: a category-tinted
/// rounded icon chip, an Oswald title, supporting body, a timestamp, plus a red
/// unread dot for items that have not been seen.
class _NoteRow extends StatelessWidget {
  const _NoteRow({required this.note});

  final AppNotification note;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final ({IconData icon, Color color}) style = _styleFor(note.type);
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
              color: style.color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(style.icon, color: style.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    if (!note.read) ...<Widget>[
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
                    Text(note.relativeTime,
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
