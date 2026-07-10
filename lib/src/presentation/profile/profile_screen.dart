import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_mode_controller.dart';
import '../auth/auth_controller.dart';
import '../widgets/glass.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final user = ref.watch(authControllerProvider).user;
    final ThemeMode mode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: <Widget>[
          GlassCard(
            radius: 24,
            padding: const EdgeInsets.all(18),
            child: Row(
              children: <Widget>[
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: FitBoxColors.red,
                  child: Icon(Icons.person, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(user?.name.isNotEmpty == true ? user!.name : 'Athlete',
                          style: text.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface)),
                      Text(user?.email ?? 'Not signed in',
                          style: text.bodyMedium
                              ?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            radius: 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(Icons.brightness_6_outlined,
                        color: cs.onSurface, size: 20),
                    const SizedBox(width: 10),
                    Text('Appearance',
                        style: text.titleSmall?.copyWith(
                            color: cs.onSurface,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                SegmentedButton<ThemeMode>(
                  segments: const <ButtonSegment<ThemeMode>>[
                    ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.brightness_auto),
                        label: Text('System')),
                    ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode),
                        label: Text('Light')),
                    ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode),
                        label: Text('Dark')),
                  ],
                  selected: <ThemeMode>{mode},
                  showSelectedIcon: false,
                  onSelectionChanged: (Set<ThemeMode> s) =>
                      ref.read(themeModeProvider.notifier).set(s.first),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Column(
              children: <Widget>[
                const _MenuItem(
                    icon: Icons.emoji_events_outlined, label: 'Leaderboard'),
                const _MenuItem(icon: Icons.flag_outlined, label: 'Goals'),
                _MenuItem(
                  icon: Icons.lock_outline,
                  label: 'Set / change password',
                  onTap: () => context.push('/change-password'),
                ),
                const _MenuItem(icon: Icons.help_outline, label: 'Help & support'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _confirmLogout(context, ref),
            icon: const Icon(Icons.logout),
            label: const Text('Log out'),
            style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50)),
          ),
        ]
            .animate(interval: 70.ms)
            .fadeIn(duration: 320.ms)
            .slideY(begin: 0.12, end: 0, curve: Curves.easeOut),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to log in again to continue.'),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Log out')),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: cs.onSurfaceVariant),
      title: Text(label, style: TextStyle(color: cs.onSurface)),
      trailing:
          Icon(Icons.chevron_right, color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
      onTap: onTap ?? () {},
    );
  }
}
