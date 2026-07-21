import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/run_activity.dart';
import '../../presentation/activity/activity_screen.dart';
import '../../presentation/auth/auth_controller.dart';
import '../../presentation/auth/auth_landing_screen.dart';
import '../../presentation/auth/login_screen.dart';
import '../../presentation/auth/reset_password_screen.dart';
import '../../presentation/auth/signup_screen.dart';
import '../../presentation/goals/goals_screen.dart';
import '../../presentation/home/home_screen.dart';
import '../../presentation/leaderboard/leaderboard_screen.dart';
import '../../presentation/notifications/notifications_screen.dart';
import '../../presentation/onboarding/onboarding_controller.dart';
import '../../presentation/onboarding/onboarding_screen.dart';
import '../../presentation/profile/change_password_screen.dart';
import '../../presentation/profile/profile_screen.dart';
import '../../presentation/run/record_run_screen.dart';
import '../../presentation/run/run_summary_screen.dart';
import '../../presentation/settings/settings_screen.dart';
import '../../presentation/shell/app_shell.dart';
import '../../presentation/splash/splash_screen.dart';
import '../../presentation/territory/territory_screen.dart';
import '../../presentation/wallet/wallet_screen.dart';

/// App navigation. Auth state drives redirects: unknown → splash, first run →
/// onboarding, signed out → login, signed in → the bottom-nav shell.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, _) => refresh.value++);
  ref.listen(onboardingSeenProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final status = ref.read(authControllerProvider).status;
      final bool seen = ref.read(onboardingSeenProvider);
      final loc = state.matchedLocation;
      final atSplash = loc == '/splash';
      final atOnboarding = loc == '/onboarding';
      final atAuth = loc == '/login' ||
          loc == '/signin' ||
          loc == '/signup' ||
          loc == '/reset';

      if (status == AuthStatus.unknown) {
        return atSplash ? null : '/splash';
      }
      if (status == AuthStatus.unauthenticated) {
        if (!seen) return atOnboarding ? null : '/onboarding';
        return atAuth ? null : '/login';
      }
      // Authenticated: keep them out of splash/onboarding/auth screens.
      if (atSplash || atOnboarding || atAuth) return '/home';
      return null;
    },
    routes: <RouteBase>[
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (_, _) => const AuthLandingScreen()),
      GoRoute(path: '/signin', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, _) => const SignupScreen()),
      GoRoute(path: '/reset', builder: (_, _) => const ResetPasswordScreen()),
      GoRoute(
          path: '/change-password',
          builder: (_, _) => const ChangePasswordScreen()),
      // Full-screen pushed routes.
      GoRoute(path: '/record-run', builder: (_, _) => const RecordRunScreen()),
      GoRoute(
        path: '/run-summary',
        builder: (_, GoRouterState s) =>
            RunSummaryScreen(run: s.extra as RunActivity?),
      ),
      GoRoute(path: '/leaderboard', builder: (_, _) => const LeaderboardScreen()),
      GoRoute(path: '/goals', builder: (_, _) => const GoalsScreen()),
      GoRoute(
          path: '/notifications',
          builder: (_, _) => const NotificationsScreen()),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      StatefulShellRoute.indexedStack(
        builder: (BuildContext context, GoRouterState state,
                StatefulNavigationShell navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(routes: <RouteBase>[
            GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: <RouteBase>[
            GoRoute(
                path: '/territory',
                builder: (_, _) => const TerritoryScreen()),
          ]),
          StatefulShellBranch(routes: <RouteBase>[
            GoRoute(
                path: '/activity', builder: (_, _) => const ActivityScreen()),
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
