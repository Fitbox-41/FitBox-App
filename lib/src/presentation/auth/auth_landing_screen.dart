import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
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
      body: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              const Expanded(child: HeroCarousel(slides: _slides)),
              _authSheet(context),
            ],
          ),
          if (signingIn)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x99000000),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  /// The dark auth sheet. Wrapped in a dark theme so the logo, glass buttons and
  /// text always read light-on-dark, regardless of the app's light/dark setting.
  Widget _authSheet(BuildContext context) {
    return Theme(
      data: AppTheme.dark(),
      child: Builder(
        builder: (BuildContext ctx) {
          final double bottomInset = MediaQuery.paddingOf(ctx).bottom;
          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: FitBoxColors.bgBottomDark,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 24,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            padding: EdgeInsets.fromLTRB(24, 22, 24, bottomInset + 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const LogoBadge(width: 150, glow: false),
                const SizedBox(height: 6),
                Text('RUN · CAPTURE · EARN',
                    style: AppTypography.label(
                        size: 12, color: Colors.white.withValues(alpha: 0.6))),
                const SizedBox(height: 22),
                AppleButton(onPressed: _apple),
                const SizedBox(height: 12),
                if (kIsWeb)
                  Center(child: googleSignInWebButton())
                else
                  GoogleButton(onPressed: _google),
                const SizedBox(height: 18),
                Row(
                  children: <Widget>[
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('OR',
                          style: AppTypography.label(
                              size: 12,
                              color: Colors.white.withValues(alpha: 0.5))),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 18),
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
                const SizedBox(height: 16),
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
                  style: AppTypography.caption(
                      size: 11, color: Colors.white.withValues(alpha: 0.5)),
                ),
              ],
            ),
          );
        },
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
    return SizedBox(
      height: 52,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(
            color: emphasized
                ? FitBoxColors.red
                : Colors.white.withValues(alpha: 0.3),
            width: emphasized ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Text(
              label.toUpperCase(),
              style: AppTypography.button(
                  size: 13,
                  color: emphasized ? FitBoxColors.red : Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
