import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';

/// Persistent app scaffold. Phones get a frosted-glass bottom bar; wider screens
/// get a side navigation rail, with content centred and width-capped.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const List<({IconData icon, IconData active, String label})> _tabs = [
    (icon: Icons.home_outlined, active: Icons.home, label: 'Home'),
    (
      icon: Icons.directions_run_outlined,
      active: Icons.directions_run,
      label: 'Activity'
    ),
    (
      icon: Icons.account_balance_wallet_outlined,
      active: Icons.account_balance_wallet,
      label: 'Wallet'
    ),
    (icon: Icons.person_outline, active: Icons.person, label: 'Profile'),
  ];

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool wide = MediaQuery.sizeOf(context).width >= 800;
    final Brightness b = Theme.of(context).brightness;
    final ColorScheme cs = Theme.of(context).colorScheme;

    final Widget content = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: navigationShell,
      ),
    );

    if (wide) {
      return Scaffold(
        body: Row(
          children: <Widget>[
            NavigationRail(
              backgroundColor: FitBoxColors.glassFill(b),
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _onTap,
              labelType: NavigationRailLabelType.all,
              indicatorColor: FitBoxColors.red.withValues(alpha: 0.25),
              destinations: <NavigationRailDestination>[
                for (final t in _tabs)
                  NavigationRailDestination(
                    icon: Icon(t.icon),
                    selectedIcon: Icon(t.active, color: cs.onSurface),
                    label: Text(t.label),
                  ),
              ],
            ),
            Expanded(child: content),
          ],
        ),
      );
    }

    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: FitBoxColors.glassFill(b),
              border: Border(
                top: BorderSide(color: FitBoxColors.glassStroke(b)),
              ),
            ),
            child: NavigationBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              indicatorColor: FitBoxColors.red.withValues(alpha: 0.28),
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _onTap,
              destinations: <NavigationDestination>[
                for (final t in _tabs)
                  NavigationDestination(
                    icon: Icon(t.icon),
                    selectedIcon: Icon(t.active, color: cs.onSurface),
                    label: t.label,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
