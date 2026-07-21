import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../widgets/glass.dart';
import '../widgets/motion.dart';
import '../widgets/theme_selector.dart';

/// App settings — grouped iOS-style glass lists. Appearance is live (persisted);
/// units / notification toggles are wired to local state for now.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _metric = true;
  bool _pushWorkout = true;
  bool _pushWeekly = true;

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
                title: 'Privacy',
                onTap: () {}),
            _divider(cs),
            _LinkRow(
              icon: Icons.info_outline,
              title: 'About FitBox',
              trailing: 'v1.1.0',
              onTap: () {},
            ),
          ]),
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
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final String? trailing;

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
                    style: AppTypography.title(size: 16, color: cs.onSurface)),
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
