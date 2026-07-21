import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../services/api_client.dart';
import '../widgets/glass.dart';
import '../widgets/hero_carousel.dart';
import '../widgets/social_buttons.dart';
import 'auth_controller.dart';
import 'google_web_button.dart';

/// The first screen users see (unauthenticated): a full-bleed hero carousel with
/// a dark auth sheet — Continue with Apple / Google, Sign In, Create Account.
/// Inspired by Strava / Nike Run Club / Adidas Running (see design/custom/login).
class AuthLandingScreen extends ConsumerStatefulWidget {
  const AuthLandingScreen({super.key});

  @override
  ConsumerState<AuthLandingScreen> createState() => _AuthLandingScreenState();
}

class _AuthLandingScreenState extends ConsumerState<AuthLandingScreen> {
  static const List<HeroSlide> _slides = <HeroSlide>[
    HeroSlide(
      image: 'assets/hero/login1.png',
      heading: 'Move every day',
      caption: 'Track every run, walk and workout effortlessly.',
    ),
    HeroSlide(
      image: 'assets/hero/login2.png',
      heading: 'Know your progress',
      caption: 'See beautiful insights and performance trends.',
    ),
    HeroSlide(
      image: 'assets/hero/login3.png',
      heading: 'Compete with friends',
      caption: 'Stay motivated through challenges and territory.',
    ),
    HeroSlide(
      image: 'assets/hero/login4.png',
      heading: 'Become your best',
      caption: 'Build consistency and improve every week.',
    ),
  ];

  Future<void> _google() async {
    try {
      await ref.read(authControllerProvider.notifier).signInWithGoogle();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(messageFromError(e))));
    }
  }

  void _apple() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Sign in with Apple is coming soon.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool signingIn = ref.watch(googleSigningInProvider);
    return Scaffold(
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints c) {
          final double h = c.maxHeight;
          // Auth sheet takes ~38% of the height → the hero photo shows ~62%.
          final double sheetH = (h * 0.38).clamp(330.0, 470.0);
          const double overlap = 28; // sheet blends up over the photo

          return Stack(
            children: <Widget>[
              // Hero photo fills the whole screen; content sits above the sheet.
              Positioned.fill(
                child: HeroCarousel(
                  slides: _slides,
                  bottomInset: sheetH - overlap,
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: sheetH,
                child: _authSheet(context),
              ),
              if (signingIn)
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.6),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// The auth sheet. Theme-aware (follows the phone's light/dark setting like the
  /// rest of the app). Its top edge fades in from transparent so the hero photo
  /// blends smoothly into the sheet instead of a hard cut.
  Widget _authSheet(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color surface =
        isDark ? FitBoxColors.bgBottomDark : const Color(0xFFF6F7F9);
    final Color muted = cs.onSurfaceVariant;
    final double safeBottom = MediaQuery.paddingOf(context).bottom;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        // Transparent → solid: the top ~14% fades in over the photo (the blend).
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            surface.withValues(alpha: 0.0),
            surface.withValues(alpha: 0.75),
            surface,
            surface,
          ],
          stops: const <double>[0.0, 0.07, 0.16, 1.0],
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 30, 24, safeBottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const LogoBadge(width: 132, glow: false),
            const SizedBox(height: 4),
            Text('RUN · CAPTURE · EARN',
                style: AppTypography.label(size: 11, color: muted)),
            const SizedBox(height: 20),
            AppleButton(onPressed: _apple),
            const SizedBox(height: 10),
            if (kIsWeb)
              Center(child: googleSignInWebButton())
            else
              GoogleButton(onPressed: _google),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('OR',
                      style: AppTypography.label(size: 11, color: muted)),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: _OutlineButton(
                    label: 'Sign In',
                    onTap: () => context.push('/signin'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _OutlineButton(
                    label: 'Create Account',
                    emphasized: true,
                    onTap: () => context.push('/signup'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text.rich(
              TextSpan(
                text: 'By continuing, you agree to our ',
                children: const <TextSpan>[
                  TextSpan(
                      text: 'Terms',
                      style: TextStyle(decoration: TextDecoration.underline)),
                  TextSpan(text: ' & '),
                  TextSpan(
                      text: 'Privacy Policy',
                      style: TextStyle(decoration: TextDecoration.underline)),
                ],
              ),
              textAlign: TextAlign.center,
              style: AppTypography.caption(size: 11, color: muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rectangular outlined button (Adidas-style) with an uppercase Oswald label.
class _OutlineButton extends StatelessWidget {
  const _OutlineButton({
    required this.label,
    required this.onTap,
    this.emphasized = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color fg = emphasized ? FitBoxColors.red : cs.onSurface;
    return SizedBox(
      height: 52,
      child: Material(
        color: emphasized
            ? FitBoxColors.red.withValues(alpha: 0.06)
            : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(
            color: emphasized
                ? FitBoxColors.red
                : cs.onSurface.withValues(alpha: 0.28),
            width: emphasized ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Center(
            child: Text(
              label.toUpperCase(),
              style: AppTypography.button(size: 13, color: fg),
            ),
          ),
        ),
      ),
    );
  }
}
