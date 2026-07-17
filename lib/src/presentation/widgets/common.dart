import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'glass.dart';

/// A compact stat tile (icon + value + label) used across the dashboard —
/// colored icon, rounded data numeral, uppercase caps label.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return GlassCard(
      radius: 22,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 18),
      child: Column(
        children: <Widget>[
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 10),
          Text(value,
              style: AppText.data(context, size: 24, color: cs.onSurface)),
          const SizedBox(height: 4),
          Text(label.toUpperCase(), style: AppText.labelCaps(context, size: 11)),
        ],
      ),
    );
  }
}

/// Uppercase, wide-tracked technical label — used for card sub-headers
/// ("TODAY'S ACTIVITY", "THIS WEEK").
class CardLabel extends StatelessWidget {
  const CardLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text.toUpperCase(), style: AppText.labelCaps(context));
}

/// Shown when an async provider fails, with a retry action.
class AsyncRetry extends StatelessWidget {
  const AsyncRetry({super.key, required this.onRetry, this.message});

  final VoidCallback onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.cloud_off, size: 40, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              message ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

/// A left-aligned kinetic (italic) section header ("Ledger", "Recent activity").
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Text(title, style: AppText.kinetic(context, size: 22)),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
