import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_mode_controller.dart';

/// System / Light / Dark segmented control — equal thirds, red selected pill.
class ThemeSelector extends ConsumerWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode mode = ref.watch(themeModeProvider);
    final ColorScheme cs = Theme.of(context).colorScheme;

    Widget seg(String label, ThemeMode value) {
      final bool active = mode == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => ref.read(themeModeProvider.notifier).set(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.all(4),
            padding: const EdgeInsets.symmetric(vertical: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? FitBoxColors.red : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              label,
              style: platformFont(
                size: 14,
                weight: FontWeight.w600,
                color: active ? Colors.white : cs.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: <Widget>[
          seg('System', ThemeMode.system),
          seg('Light', ThemeMode.light),
          seg('Dark', ThemeMode.dark),
        ],
      ),
    );
  }
}
