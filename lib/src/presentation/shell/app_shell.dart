import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';

/// Persistent app scaffold. Phones get a floating frosted-glass pill nav; wider
/// screens get a side navigation rail, with content centred and width-capped.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const List<({IconData icon, IconData active, String label})> _tabs = [
    (icon: Icons.home_outlined, active: Icons.home, label: 'Home'),
    (icon: Icons.map_outlined, active: Icons.map, label: 'Territory'),
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
              indicatorColor: FitBoxColors.red.withValues(alpha: 0.22),
              destinations: <NavigationRailDestination>[
                for (final t in _tabs)
                  NavigationRailDestination(
                    icon: Icon(t.icon),
                    selectedIcon: Icon(t.active, color: FitBoxColors.red),
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
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: _GlassPillNav(
            tabs: _tabs,
            currentIndex: navigationShell.currentIndex,
            onTap: _onTap,
            brightness: b,
            onSurfaceVariant: cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// A detached, floating glass pill holding the tab icons — active = red.
class _GlassPillNav extends StatelessWidget {
  const _GlassPillNav({
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
    required this.brightness,
    required this.onSurfaceVariant,
  });

  final List<({IconData icon, IconData active, String label})> tabs;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Brightness brightness;
  final Color onSurfaceVariant;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: FitBoxColors.glassFill(brightness),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: FitBoxColors.glassStroke(brightness)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                children: <Widget>[
                  for (int i = 0; i < tabs.length; i++)
                    Expanded(
                      child: _NavIcon(
                        selected: i == currentIndex,
                        icon: i == currentIndex ? tabs[i].active : tabs[i].icon,
                        label: tabs[i].label,
                        inactiveColor: onSurfaceVariant,
                        onTap: () => onTap(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.selected,
    required this.icon,
    required this.label,
    required this.inactiveColor,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final Color inactiveColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = selected ? FitBoxColors.red : inactiveColor;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AnimatedScale(
              scale: selected ? 1.1 : 1,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 3),
            // A small red dot marks the active tab (matches the design).
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: selected ? 5 : 0,
              height: selected ? 5 : 0,
              decoration: const BoxDecoration(
                color: FitBoxColors.red,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
