import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_controller.dart';
import '../widgets/external_link.dart';
import '../widgets/glass.dart';
import '../widgets/motion.dart';
import '../widgets/theme_selector.dart';

/// App settings — grouped iOS-style glass lists. Appearance is live (persisted);
/// units / notification toggles are wired to local state for now.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _metric = true;
  bool _pushWorkout = true;
  bool _pushWeekly = true;
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((PackageInfo info) {
      if (mounted) setState(() => _version = 'v${info.version}');
    }).catchError((_) {/* leave blank rather than show a wrong number */});
  }

  Future<void> _showAbout(BuildContext context) async {
    showAboutDialog(
      context: context,
      applicationName: 'FitBox',
      applicationVersion: _version,
      applicationLegalese: '© ${DateTime.now().year} FitBox Sports, Jalandhar, Punjab, India',
      children: <Widget>[
        const SizedBox(height: 12),
        const Text(
          'Track your runs, claim territory and earn rewards you can spend on '
          'FitBox Sports gym equipment.',
        ),
        const SizedBox(height: 12),
        Text('Support: ${AppConfig.supportEmail}'),
      ],
    );
  }

  /// Two deliberate steps: a dialog that says exactly what goes, and a typed
  /// confirmation. Account deletion is irreversible and sits one tap from
  /// "About", so a single "Are you sure?" is too easy to nod through.
  Future<void> _confirmDelete() async {
    final bool sure = await _askToDelete() ?? false;
    if (!sure || !mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await ref.read(authControllerProvider.notifier).deleteAccount();
      // The router sends us to the sign-in screen the moment auth state flips;
      // just close the spinner.
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not delete your account. Nothing was removed — '
            'check your connection and try again.',
          ),
        ),
      );
    }
  }

  Future<bool?> _askToDelete() {
    final TextEditingController typed = TextEditingController();
    return showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => StatefulBuilder(
        builder: (BuildContext ctx, void Function(void Function()) setLocal) {
          final bool ready = typed.text.trim().toUpperCase() == 'DELETE';
          return AlertDialog(
            title: const Text('Delete account?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'This permanently deletes your FitBox account and everything '
                  'in it: your runs, the territory you hold, your points and '
                  'their history, and your notifications.\n\n'
                  'It cannot be undone, and it signs you out of the shop too.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: typed,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (_) => setLocal(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Type DELETE to confirm',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: ready ? () => Navigator.of(ctx).pop(true) : null,
                style: TextButton.styleFrom(foregroundColor: FitBoxColors.red),
                child: const Text('Delete for ever'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: <Widget>[
          _group(context, 'Appearance', <Widget>[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: ThemeSelector(),
            ),
          ]),
          const SizedBox(height: 20),
          _group(context, 'Units', <Widget>[
            _SwitchRow(
              icon: Icons.straighten,
              title: 'Use kilometres',
              subtitle: _metric ? 'km · kg' : 'mi · lb',
              value: _metric,
              onChanged: (bool v) => setState(() => _metric = v),
            ),
          ]),
          const SizedBox(height: 20),
          _group(context, 'Notifications', <Widget>[
            _SwitchRow(
              icon: Icons.directions_run,
              title: 'Workout reminders',
              value: _pushWorkout,
              onChanged: (bool v) => setState(() => _pushWorkout = v),
            ),
            _divider(cs),
            _SwitchRow(
              icon: Icons.bar_chart,
              title: 'Weekly results',
              value: _pushWeekly,
              onChanged: (bool v) => setState(() => _pushWeekly = v),
            ),
          ]),
          const SizedBox(height: 20),
          _group(context, 'About', <Widget>[
            _LinkRow(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              onTap: () => openExternalUrl(context, AppConfig.privacyPolicyUrl),
            ),
            _divider(cs),
            _LinkRow(
              icon: Icons.gavel_outlined,
              title: 'Terms & Conditions',
              onTap: () => openExternalUrl(context, AppConfig.termsUrl),
            ),
            _divider(cs),
            _LinkRow(
              icon: Icons.info_outline,
              title: 'About FitBox',
              // Read from the package rather than typed in — the hardcoded
              // string here said v1.1.0 long after the app had moved on.
              trailing: _version,
              onTap: () => _showAbout(context),
            ),
          ]),
          const SizedBox(height: 20),
          // Deleting the account has to be reachable from inside the app, not
          // only from the website — Google Play requires both routes for any
          // app that lets people sign up.
          _group(context, 'Account', <Widget>[
            _LinkRow(
              icon: Icons.delete_forever_outlined,
              title: 'Delete account',
              danger: true,
              onTap: _confirmDelete,
            ),
          ]),
          Padding(
            padding: const EdgeInsets.only(left: 6, top: 8),
            child: Text(
              'Deleting removes your runs, territory, points and notifications '
              'permanently. Past orders are kept as the shop’s records.',
              style: AppTypography.body(
                  size: 11.5, color: cs.onSurface.withValues(alpha: 0.55)),
            ),
          ),
        ].revealStagger(),
      ),
    );
  }

  Widget _divider(ColorScheme cs) => Padding(
        padding: const EdgeInsets.only(left: 62),
        child: Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.08)),
      );

  Widget _group(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 10),
          child: Text(title.toUpperCase(), style: AppText.labelCaps(context)),
        ),
        GlassCard(
          radius: 22,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(children: children),
        ),
      ],
    );
  }
}

/// A leading icon in a soft red-tinted rounded chip — the shared row motif.
class _IconChip extends StatelessWidget {
  const _IconChip(this.icon);
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: FitBoxColors.red.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(11),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: FitBoxColors.red, size: 20),
      );
}

/// A settings row with a switch control. Toggling gives a subtle haptic tick.
class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: <Widget>[
            _IconChip(icon),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(title,
                      style: AppTypography.title(size: 16, color: cs.onSurface)),
                  if (subtitle != null) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: AppTypography.caption(
                            size: 13, color: cs.onSurfaceVariant)),
                  ],
                ],
              ),
            ),
            Switch(
              value: value,
              activeThumbColor: Colors.white,
              activeTrackColor: FitBoxColors.red,
              onChanged: (bool v) {
                HapticFeedback.selectionClick();
                onChanged(v);
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// A tappable settings row that navigates / opens something, with a chevron or
/// trailing caption. Adds an Apple-style selection haptic on tap.
class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final String? trailing;

  /// Destructive rows are tinted red — the one action here that can't be undone
  /// shouldn't look like every other row.
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: <Widget>[
              _IconChip(icon),
              const SizedBox(width: 14),
              Expanded(
                child: Text(title,
                    style: AppTypography.title(
                        size: 16,
                        color: danger ? FitBoxColors.red : cs.onSurface)),
              ),
              if (trailing != null) ...<Widget>[
                Text(trailing!,
                    style: AppTypography.caption(
                        size: 13, color: cs.onSurfaceVariant)),
                const SizedBox(width: 6),
              ],
              Icon(Icons.chevron_right,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
            ],
          ),
        ),
      ),
    );
  }
}
