import 'package:flutter/material.dart';

import 'glass.dart';

/// A compact stat tile (icon + value + label) used across the dashboard.
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
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme cs = Theme.of(context).colorScheme;
    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(value,
              style: text.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold, color: cs.onSurface)),
          const SizedBox(height: 2),
          Text(label,
              style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
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

/// A left-aligned section header.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface),
      ),
    );
  }
}
