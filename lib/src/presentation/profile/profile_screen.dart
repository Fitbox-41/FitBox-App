import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../auth/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final user = ref.watch(authControllerProvider).user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: <Widget>[
          Row(
            children: <Widget>[
              const CircleAvatar(
                radius: 32,
                backgroundColor: FitBoxColors.charcoal,
                child: Icon(Icons.person, color: Colors.white, size: 34),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(user?.name.isNotEmpty == true ? user!.name : 'Athlete',
                        style: text.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    Text(user?.email ?? 'Not signed in',
                        style: text.bodyMedium
                            ?.copyWith(color: Theme.of(context).hintColor)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _MenuItem(icon: Icons.emoji_events_outlined, label: 'Leaderboard'),
          const _MenuItem(icon: Icons.flag_outlined, label: 'Goals'),
          _MenuItem(
            icon: Icons.lock_outline,
            label: 'Set / change password',
            onTap: () => context.push('/change-password'),
          ),
          const _MenuItem(icon: Icons.settings_outlined, label: 'Settings'),
          const _MenuItem(icon: Icons.help_outline, label: 'Help & support'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _confirmLogout(context, ref),
            icon: const Icon(Icons.logout),
            label: const Text('Log out'),
          ),
        ],
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
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap ?? () {},
    );
  }
}
