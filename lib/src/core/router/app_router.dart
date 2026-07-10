import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/activity/activity_screen.dart';
import '../../presentation/auth/auth_controller.dart';
import '../../presentation/auth/login_screen.dart';
import '../../presentation/auth/signup_screen.dart';
import '../../presentation/home/home_screen.dart';
import '../../presentation/profile/profile_screen.dart';
import '../../presentation/shell/app_shell.dart';
import '../../presentation/splash/splash_screen.dart';
import '../../presentation/wallet/wallet_screen.dart';

/// App navigation. Auth state drives redirects: unknown → splash, signed out →
/// login, signed in → the bottom-nav shell.
final routerProvider = Provider<GoRouter>((ref) {
  // Bridge the Riverpod auth state to a Listenable so the router re-evaluates
  // its redirect whenever auth changes.
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final status = ref.read(authControllerProvider).status;
      final loc = state.matchedLocation;
      final atSplash = loc == '/splash';
      final atAuth = loc == '/login' || loc == '/signup';

      if (status == AuthStatus.unknown) {
        return atSplash ? null : '/splash';
      }
      if (status == AuthStatus.unauthenticated) {
        return atAuth ? null : '/login';
      }
      // Authenticated: keep them out of splash/auth screens.
      if (atSplash || atAuth) return '/home';
      return null;
    },
    routes: <RouteBase>[
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, _) => const SignupScreen()),
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
});
