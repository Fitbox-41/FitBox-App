import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Persistent app scaffold. Phones get a bottom navigation bar; wider screens
/// (PC/tablet, incl. web on desktop) get a side navigation rail, with the
/// content centred and width-capped so it stays comfortable to read.
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
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _onTap,
              labelType: NavigationRailLabelType.all,
              destinations: <NavigationRailDestination>[
                for (final t in _tabs)
                  NavigationRailDestination(
                    icon: Icon(t.icon),
                    selectedIcon: Icon(t.active),
                    label: Text(t.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: content),
          ],
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTap,
        destinations: <NavigationDestination>[
          for (final t in _tabs)
            NavigationDestination(
              icon: Icon(t.icon),
              selectedIcon: Icon(t.active),
              label: t.label,
            ),
        ],
      ),
    );
  }
}
