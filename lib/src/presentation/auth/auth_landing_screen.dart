import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/external_link.dart';
import '../widgets/glass.dart';
import '../widgets/hero_carousel.dart';
import 'auth_controller.dart';

/// The first screen users see (unauthenticated): a full-bleed hero carousel with
/// a clean auth sheet — Sign In / Create Account. Google & Apple sign-in live on
/// the Sign In screen. Inspired by Strava / Nike Run Club / Adidas Running.
class AuthLandingScreen extends StatelessWidget {
  const AuthLandingScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints c) {
          final double h = c.maxHeight;
          // Sheet is tall enough to fit ALL its content (logo + tagline + both
          // buttons + terms) with no scroll, while the hero photo stays dominant.
          final double sheetH = (h * 0.45).clamp(424.0, 500.0);
          const double overlap = 28; // sheet blends up over the photo

          return Stack(
            children: <Widget>[
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
                child: const _AuthSheet(),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The auth sheet. Theme-aware (follows the phone's light/dark setting like the
/// rest of the app). Its top edge fades in from transparent so the hero photo
/// blends smoothly into the sheet instead of a hard cut.
class _AuthSheet extends ConsumerWidget {
  const _AuthSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            surface.withValues(alpha: 0.0),
            surface.withValues(alpha: 0.75),
            surface,
            surface,
          ],
          stops: const <double>[0.0, 0.08, 0.18, 1.0],
        ),
      ),
      child: SingleChildScrollView(
        // The sheet is sized to fit this content, so it never actually scrolls;
        // the scroll view is only a safety net on unusually short screens.
        padding: EdgeInsets.fromLTRB(24, 36, 24, safeBottom + 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Center(child: LogoBadge(width: 104, glow: false)),
            const SizedBox(height: 6),
            Text('RUN · CAPTURE · EARN',
                textAlign: TextAlign.center,
                style: AppTypography.label(size: 11, color: muted)),
            const SizedBox(height: 20),
            GlowButton(
              label: 'Create Account',
              icon: Icons.arrow_forward,
              onPressed: () => context.push('/signup'),
            ),
            const SizedBox(height: 10),
            _OutlineButton(
              label: 'Sign In',
              onTap: () => context.push('/signin'),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                ref.read(guestModeProvider.notifier).enter();
                context.go('/home');
              },
              child: Text('Continue as guest',
                  style: AppTypography.button(size: 13, color: muted)),
            ),
            const SizedBox(height: 6),
            // These are the agreement the user is being asked to accept, so
            // they have to actually open — underlining text that does nothing
            // is worse than not offering the link.
            Text.rich(
              TextSpan(
                text: 'By continuing, you agree to our ',
                children: <TextSpan>[
                  TextSpan(
                    text: 'Terms',
                    style: const TextStyle(decoration: TextDecoration.underline),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => openExternalUrl(context, AppConfig.termsUrl),
                  ),
                  const TextSpan(text: ' & '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: const TextStyle(decoration: TextDecoration.underline),
                    recognizer: TapGestureRecognizer()
                      ..onTap =
                          () => openExternalUrl(context, AppConfig.privacyPolicyUrl),
                  ),
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
  const _OutlineButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 54,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(color: cs.onSurface.withValues(alpha: 0.30)),
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
              style: AppTypography.button(size: 14, color: cs.onSurface),
            ),
          ),
        ),
      ),
    );
  }
}
