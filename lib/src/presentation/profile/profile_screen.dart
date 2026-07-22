import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/fitness_stats.dart';
import '../../data/providers.dart';
import '../auth/auth_controller.dart';
import '../widgets/common.dart';
import '../widgets/glass.dart';
import '../widgets/motion.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final user = ref.watch(authControllerProvider).user;
    final FitnessStats stats = ref.watch(fitnessStatsProvider);

    final String displayName =
        user?.name.isNotEmpty == true ? user!.name : 'Athlete';

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: <Widget>[
          _ProfileHeader(name: displayName, email: user?.email),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: _CountStat(
                  icon: Icons.route,
                  value: stats.distanceKm,
                  decimals: 1,
                  label: 'km today',
                  color: FitBoxColors.credit,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CountStat(
                  icon: Icons.local_fire_department,
                  value: stats.caloriesKcal.toDouble(),
                  label: 'kcal',
                  color: FitBoxColors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CountStat(
                  icon: Icons.timer_outlined,
                  value: stats.activeMinutes.toDouble(),
                  label: 'mins',
                  color: FitBoxColors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const CardLabel('Account'),
          const SizedBox(height: 10),
          GlassCard(
            radius: 22,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(
              children: <Widget>[
                _ActionRow(
                    icon: Icons.emoji_events_outlined,
                    label: 'Leaderboard',
                    onTap: () => context.push('/leaderboard')),
                _RowDivider(cs: cs),
                _ActionRow(
                    icon: Icons.flag_outlined,
                    label: 'Goals',
                    onTap: () => context.push('/goals')),
                _RowDivider(cs: cs),
                _ActionRow(
                    icon: Icons.lock_outline,
                    label: 'Set / change password',
                    onTap: () => context.push('/change-password')),
                _RowDivider(cs: cs),
                _ActionRow(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    onTap: () => context.push('/settings')),
                _RowDivider(cs: cs),
                _ActionRow(
                    icon: Icons.notifications_none,
                    label: 'Notifications',
                    onTap: () => context.push('/notifications')),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GlassCard(
            radius: 22,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            onTap: () => _confirmLogout(context, ref),
            child: _ActionRow(
              icon: Icons.logout,
              label: 'Log out',
              destructive: true,
              // Tap handled by the enclosing GlassCard.onTap.
              onTap: null,
            ),
          ),
        ].revealStagger(),
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

/// Premium header — avatar/initial in a red-glow circle, name in Oswald, email
/// in muted caption, all inside frosted glass.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.name, required this.email});

  final String name;
  final String? email;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String? initial =
        name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : null;
    return GlassCard(
      radius: 26,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: <Widget>[
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: <Color>[FitBoxColors.red, FitBoxColors.redDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: FitBoxColors.red.withValues(alpha: 0.42),
                  blurRadius: 24,
                  spreadRadius: -2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: initial != null
                ? Text(initial,
                    style: AppText.kinetic(context,
                        size: 32, color: Colors.white))
                : const Icon(Icons.person, color: Colors.white, size: 36),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(name,
                    style: AppText.kinetic(context,
                        size: 24, color: cs.onSurface)),
                const SizedBox(height: 4),
                Text(email ?? 'Not signed in',
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

/// A key stat tile with a number that counts up on first build.
class _CountStat extends StatelessWidget {
  const _CountStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.decimals = 0,
  });

  final IconData icon;
  final double value;
  final String label;
  final Color color;
  final int decimals;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return GlassCard(
      radius: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
      child: Column(
        children: <Widget>[
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 10),
          CountUpText(
            value: value,
            builder: (BuildContext context, double v) => Text(
              decimals == 0 ? v.round().toString() : v.toStringAsFixed(decimals),
              style: AppText.data(context, size: 24, color: cs.onSurface),
            ),
          ),
          const SizedBox(height: 4),
          Text(label.toUpperCase(),
              style: AppText.labelCaps(context, size: 11)),
        ],
      ),
    );
  }
}

/// A tappable account row: red-tinted icon chip, label, chevron. Destructive
/// variant tints everything with the debit/danger colour.
class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color accent = destructive ? FitBoxColors.debit : FitBoxColors.red;

    final Widget content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: AppTypography.title(
                    size: 16,
                    color: destructive ? FitBoxColors.debit : cs.onSurface)),
          ),
          if (!destructive)
            Icon(Icons.chevron_right,
                color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
        ],
      ),
    );

    if (onTap == null) {
      return ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: content,
      );
    }

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap!();
      },
      borderRadius: BorderRadius.circular(14),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: content,
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 62),
        child: Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.08)),
      );
}
