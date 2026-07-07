import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/activity/activity_screen.dart';
import '../../presentation/home/home_screen.dart';
import '../../presentation/profile/profile_screen.dart';
import '../../presentation/shell/app_shell.dart';
import '../../presentation/wallet/wallet_screen.dart';

/// App navigation. A bottom-nav shell with four branches, each preserving its
/// own state.
final GoRouter appRouter = GoRouter(
  initialLocation: '/home',
  routes: <RouteBase>[
    StatefulShellRoute.indexedStack(
      builder: (BuildContext context, GoRouterState state,
              StatefulNavigationShell navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: <StatefulShellBranch>[
        StatefulShellBranch(routes: <RouteBase>[
          GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
        ]),
        StatefulShellBranch(routes: <RouteBase>[
          GoRoute(path: '/activity', builder: (_, _) => const ActivityScreen()),
        ]),
        StatefulShellBranch(routes: <RouteBase>[
          GoRoute(path: '/wallet', builder: (_, _) => const WalletScreen()),
        ]),
        StatefulShellBranch(routes: <RouteBase>[
          GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
        ]),
      ],
    ),
  ],
);
