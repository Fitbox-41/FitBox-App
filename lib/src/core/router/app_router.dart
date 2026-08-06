import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/run_activity.dart';
import '../../data/models/run_result.dart';
import '../../presentation/widgets/glass.dart';
import '../../presentation/activity/activity_screen.dart';
import '../../presentation/auth/auth_controller.dart';
import '../../presentation/auth/auth_landing_screen.dart';
import '../../presentation/auth/login_screen.dart';
import '../../presentation/auth/reset_password_screen.dart';
import '../../presentation/auth/signup_screen.dart';
import '../../presentation/challenges/challenges_screen.dart';
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

/// Wraps a pushed screen in the native iOS page transition (right-to-left slide
/// + interactive swipe-back gesture). The child gets an opaque AppBackground so
/// the slide reads as a solid screen (no see-through jank during the push).
Page<void> _ios(Widget child) =>
    CupertinoPage<void>(child: AppBackground(child: child));

/// A smooth cross-fade — used for the auth screens so moving between the
/// landing and Sign In / Create Account blends instead of a hard slide.
Page<void> _fade(Widget child) => CustomTransitionPage<void>(
      child: child,
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      transitionsBuilder: (BuildContext context, Animation<double> animation,
              Animation<double> secondary, Widget child) =>
          FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      ),
    );

/// App navigation. Auth state drives redirects: unknown → splash, first run →
/// onboarding, signed out → login, signed in → the bottom-nav shell.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, AuthState next) {
    // Signing in ends a guest session.
    if (next.status == AuthStatus.authenticated) {
      ref.read(guestModeProvider.notifier).exit();
    }
    refresh.value++;
  });
  ref.listen(onboardingSeenProvider, (_, _) => refresh.value++);
  ref.listen(guestModeProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final status = ref.read(authControllerProvider).status;
      final bool seen = ref.read(onboardingSeenProvider);
      final bool guest = ref.read(guestModeProvider);
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
        // Guests browse the app; they may still open the auth screens to sign
        // in. Only keep them out of splash/onboarding.
        if (guest) return (atSplash || atOnboarding) ? '/home' : null;
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
      // Auth screens cross-fade with the landing (smooth blend, no hard slide).
      GoRoute(
          path: '/signin',
          pageBuilder: (_, _) => _fade(const LoginScreen())),
      GoRoute(
          path: '/signup',
          pageBuilder: (_, _) => _fade(const SignupScreen())),
      GoRoute(
          path: '/reset',
          pageBuilder: (_, _) => _fade(const ResetPasswordScreen())),
      GoRoute(
          path: '/change-password',
          pageBuilder: (_, _) => _ios(const ChangePasswordScreen())),
      // Full-screen pushed routes.
      GoRoute(
          path: '/record-run',
          pageBuilder: (_, _) => _ios(const RecordRunScreen())),
      GoRoute(
        path: '/run-summary',
        pageBuilder: (_, GoRouterState s) {
          final Object? e = s.extra;
          if (e is RunResult) {
            return _ios(RunSummaryScreen(
              run: e.run,
              claimedAreaSqm: e.claimedAreaSqm,
              sync: e.sync,
            ));
          }
          return _ios(RunSummaryScreen(run: e as RunActivity?));
        },
      ),
      GoRoute(
          path: '/leaderboard',
          pageBuilder: (_, _) => _ios(const LeaderboardScreen())),
      GoRoute(path: '/goals', pageBuilder: (_, _) => _ios(const GoalsScreen())),
      GoRoute(
          path: '/challenges',
          pageBuilder: (_, _) => _ios(const ChallengesScreen())),
      GoRoute(
          path: '/notifications',
          pageBuilder: (_, _) => _ios(const NotificationsScreen())),
      GoRoute(
          path: '/settings',
          pageBuilder: (_, _) => _ios(const SettingsScreen())),
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
