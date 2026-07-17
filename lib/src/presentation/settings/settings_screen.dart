import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../widgets/glass.dart';
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
            _switchTile(cs, 'Use kilometres', _metric,
                (bool v) => setState(() => _metric = v),
                subtitle: _metric ? 'km · kg' : 'mi · lb'),
          ]),
          const SizedBox(height: 20),
          _group(context, 'Notifications', <Widget>[
            _switchTile(cs, 'Workout reminders', _pushWorkout,
                (bool v) => setState(() => _pushWorkout = v)),
            Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.08)),
            _switchTile(cs, 'Weekly results', _pushWeekly,
                (bool v) => setState(() => _pushWeekly = v)),
          ]),
          const SizedBox(height: 20),
          _group(context, 'About', <Widget>[
            _linkTile(cs, Icons.privacy_tip_outlined, 'Privacy'),
            Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.08)),
            _linkTile(cs, Icons.info_outline, 'About FitBox', trailing: 'v1.1.0'),
          ]),
        ],
      ),
    );
  }

  Widget _group(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 8),
          child: Text(title.toUpperCase(), style: AppText.labelCaps(context)),
        ),
        GlassCard(
          radius: 22,
          padding: EdgeInsets.zero,
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _switchTile(
      ColorScheme cs, String label, bool value, ValueChanged<bool> onChanged,
      {String? subtitle}) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(label, style: TextStyle(color: cs.onSurface)),
      subtitle: subtitle == null
          ? null
          : Text(subtitle, style: TextStyle(color: cs.onSurfaceVariant)),
      value: value,
      activeThumbColor: Colors.white,
      activeTrackColor: FitBoxColors.red,
      onChanged: onChanged,
    );
  }

  Widget _linkTile(ColorScheme cs, IconData icon, String label,
      {String? trailing}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(icon, color: cs.onSurfaceVariant),
      title: Text(label, style: TextStyle(color: cs.onSurface)),
      trailing: Text(trailing ?? '',
          style: TextStyle(color: cs.onSurfaceVariant)),
      onTap: () {},
    );
  }
}
