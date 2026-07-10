import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// Root widget for the FitBox application.
class FitBoxApp extends ConsumerWidget {
  const FitBoxApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'FitBox',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: router,
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        final double width = MediaQuery.sizeOf(context).width;
        // Phones (incl. mobile web): use the full width.
        if (width <= 600) return child;
        // Larger screens (PC/tablet): present the mobile app centred in a
        // phone-sized frame so it stays legible and on-brand.
        return ColoredBox(
          color: const Color(0xFF111213),
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: SizedBox(
                width: 430,
                height: MediaQuery.sizeOf(context).height.clamp(0, 920),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
