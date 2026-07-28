import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_controller.dart';
import 'presentation/auth/auth_controller.dart';
import 'presentation/widgets/glass.dart';
import 'services/push_service.dart';

/// Messenger key so we can surface feedback (e.g. from a home-screen widget
/// launch) without a screen-local context.
final GlobalKey<ScaffoldMessengerState> rootMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Root widget for the FitBox application.
class FitBoxApp extends ConsumerStatefulWidget {
  const FitBoxApp({super.key});

  @override
  ConsumerState<FitBoxApp> createState() => _FitBoxAppState();
}

class _FitBoxAppState extends ConsumerState<FitBoxApp> {
  StreamSubscription<Uri?>? _widgetClicks;

  @override
  void initState() {
    super.initState();
    // Home-screen widget → app deep links (Android now, iOS once the WidgetKit
    // extension is added). No-op on web.
    if (!kIsWeb) {
      // Shared container id for the iOS widget extension (harmless on Android).
      HomeWidget.setAppGroupId('group.com.fitboxsports.app');
      HomeWidget.initiallyLaunchedFromHomeWidget().then(_handleWidgetUri);
      _widgetClicks = HomeWidget.widgetClicked.listen(_handleWidgetUri);

      // Register for push once the user is signed in (the token is stored
      // against their account, so it needs an authenticated session).
      if (ref.read(authControllerProvider).status == AuthStatus.authenticated) {
        ref.read(pushServiceProvider).register();
      }
      ref.listenManual(authControllerProvider, (AuthState? prev, AuthState next) {
        if (next.status == AuthStatus.authenticated &&
            prev?.status != AuthStatus.authenticated) {
          ref.read(pushServiceProvider).register();
        }
      });
    }
  }

  @override
  void dispose() {
    _widgetClicks?.cancel();
    super.dispose();
  }

  void _handleWidgetUri(Uri? uri) {
    if (uri == null) return;
    // fitbox://start-run  → jump straight into run recording.
    if (uri.host == 'start-run' || uri.path.contains('start-run')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(routerProvider).go('/record-run');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'FitBox',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootMessengerKey,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      themeAnimationDuration: const Duration(milliseconds: 350),
      themeAnimationCurve: Curves.easeInOut,
      routerConfig: router,
      builder: (context, child) =>
          AppBackground(child: child ?? const SizedBox.shrink()),
    );
  }
}
