import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: <Widget>[
          Row(
            children: <Widget>[
              const CircleAvatar(
                radius: 32,
                backgroundColor: FitBoxColors.green,
                child: Icon(Icons.person, color: Colors.white, size: 34),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Athlete',
                      style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  Text('Not signed in',
                      style: text.bodyMedium
                          ?.copyWith(color: Theme.of(context).hintColor)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _MenuItem(icon: Icons.emoji_events_outlined, label: 'Leaderboard'),
          const _MenuItem(icon: Icons.flag_outlined, label: 'Goals'),
          const _MenuItem(icon: Icons.settings_outlined, label: 'Settings'),
          const _MenuItem(icon: Icons.help_outline, label: 'Help & support'),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: () {},
            icon: const Icon(Icons.login),
            label: const Text('Sign in'),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {},
    );
  }
}
