import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_mode_controller.dart';
import '../widgets/glass.dart';
import 'onboarding_controller.dart';

/// First-run flow, built to the auth-landing quality bar: a swipeable three-step
/// journey — Welcome (hero) → Choose Theme → Permissions — with a persistent
/// bottom bar (animated dots + a primary CTA whose label adapts per step).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;
  bool _requesting = false;

  static const int _lastPage = 2;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(onboardingSeenProvider.notifier).markSeen();
    if (mounted) context.go('/login');
  }

  void _next() {
    HapticFeedback.selectionClick();
    if (_page < _lastPage) {
      _controller.nextPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
    }
  }

  void _back() {
    HapticFeedback.selectionClick();
    _controller.previousPage(
        duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
  }

  Future<void> _requestPermissionsAndFinish() async {
    HapticFeedback.mediumImpact();
    setState(() => _requesting = true);
    try {
      await <Permission>[
        Permission.activityRecognition,
        Permission.notification,
      ].request();
    } catch (_) {
      /* never block onboarding on a permission hiccup */
    } finally {
      if (mounted) setState(() => _requesting = false);
      await _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // Top bar: back (after page 0) + Skip.
            SizedBox(
              height: 48,
              child: Row(
                children: <Widget>[
                  if (_page > 0)
                    IconButton(
                      onPressed: _back,
                      icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                    )
                  else
                    const SizedBox(width: 8),
                  const Spacer(),
                  TextButton(
                    onPressed: _finish,
                    child: Text('Skip',
                        style: AppTypography.button(
                            size: 13, color: cs.onSurfaceVariant)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (int i) => setState(() => _page = i),
                children: <Widget>[
                  _WelcomePage(),
                  _ThemePage(),
                  _PermissionsPage(),
                ],
              ),
            ),
            _bottomBar(cs),
          ],
        ),
      ),
    );
  }

  Widget _bottomBar(ColorScheme cs) {
    final bool isLast = _page == _lastPage;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List<Widget>.generate(_lastPage + 1, (int i) {
              final bool active = i == _page;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: active ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: active
                      ? FitBoxColors.red
                      : cs.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 18),
          GlowButton(
            label: switch (_page) {
              0 => 'Get Started',
              1 => 'Continue',
              _ => 'Allow & Continue',
            },
            icon: isLast ? Icons.check_rounded : Icons.arrow_forward,
            loading: _requesting,
            onPressed: _requesting
                ? null
                : (isLast ? _requestPermissionsAndFinish : _next),
          ),
        ],
      ),
    );
  }
}

/// Step 1 — a full hero image with a smooth blend into a headline (same visual
/// language as the auth landing).
class _WelcomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
      child: Column(
        children: <Widget>[
          const LogoBadge(width: 118, glow: false),
          const SizedBox(height: 18),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Image.asset('assets/hero/onboard1.png',
                      fit: BoxFit.cover, cacheWidth: 1080),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          Color(0x22000000),
                          Color(0x00000000),
                          Color(0x99000000),
                          Color(0xE6000000),
                        ],
                        stops: <double>[0.0, 0.4, 0.78, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 22,
                    right: 22,
                    bottom: 26,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          'WELCOME TO\nFITBOX SPORTS',
                          style: AppTypography.heading(size: 27, color: Colors.white)
                              .copyWith(height: 1.05),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Run, capture your city and earn rewards — '
                          'your fitness, turned into a game.',
                          style: AppTypography.body(size: 14, color: Colors.white)
                              .copyWith(color: Colors.white.withValues(alpha: 0.85)),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Step 2 — theme preference, applied live as the user taps.
class _ThemePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode mode = ref.watch(themeModeProvider);

    void pick(ThemeMode m) {
      HapticFeedback.selectionClick();
      ref.read(themeModeProvider.notifier).set(m);
    }

    return Column(
      children: <Widget>[
        const _HeroHeader(
          image: 'assets/hero/onboard2.png',
          headline: 'THEME\nPREFERENCE',
          subtitle: 'Pick how FitBox looks. Change it anytime in Settings.',
          height: 250,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _ThemeCard(
                        label: 'Dark',
                        icon: Icons.dark_mode_rounded,
                        selected: mode == ThemeMode.dark,
                        onTap: () => pick(ThemeMode.dark),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ThemeCard(
                        label: 'Light',
                        icon: Icons.light_mode_rounded,
                        selected: mode == ThemeMode.light,
                        onTap: () => pick(ThemeMode.light),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _ThemeCard(
                  label: 'Follow System',
                  icon: Icons.brightness_auto_rounded,
                  selected: mode == ThemeMode.system,
                  onTap: () => pick(ThemeMode.system),
                  wide: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.wide = false,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: Material(
        color: selected
            ? FitBoxColors.red.withValues(alpha: 0.10)
            : cs.onSurface.withValues(alpha: 0.04),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected
                ? FitBoxColors.red
                : cs.onSurface.withValues(alpha: 0.12),
            width: selected ? 1.6 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: wide ? 16 : 26, horizontal: 16),
            child: wide
                ? Row(
                    children: <Widget>[
                      Icon(icon,
                          color: selected ? FitBoxColors.red : cs.onSurface,
                          size: 24),
                      const SizedBox(width: 12),
                      Text(label.toUpperCase(),
                          style: AppTypography.label(
                              size: 13,
                              color: selected ? FitBoxColors.red : cs.onSurface)),
                      const Spacer(),
                      if (selected)
                        const Icon(Icons.check_circle_rounded,
                            color: FitBoxColors.red, size: 22),
                    ],
                  )
                : Column(
                    children: <Widget>[
                      Icon(icon,
                          color: selected ? FitBoxColors.red : cs.onSurface,
                          size: 34),
                      const SizedBox(height: 14),
                      Text(label.toUpperCase(),
                          style: AppTypography.label(
                              size: 13,
                              color: selected ? FitBoxColors.red : cs.onSurface)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Step 3 — the permissions we rely on, explained before the OS prompt.
class _PermissionsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const _HeroHeader(
          image: 'assets/hero/onboard3.png',
          headline: 'STAY IN\nTHE FLOW',
          subtitle: 'A couple of permissions keep your runs tracked. '
              'You are always in control.',
          height: 250,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 8),
            child: Column(
              children: const <Widget>[
                _PermRow(
                  icon: Icons.directions_run_rounded,
                  title: 'Motion & Fitness',
                  body: 'Count your steps, distance and pace during a run.',
                ),
                SizedBox(height: 16),
                _PermRow(
                  icon: Icons.notifications_active_rounded,
                  title: 'Notifications',
                  body: 'Live run updates, dares and reward alerts.',
                ),
                SizedBox(height: 16),
                _PermRow(
                  icon: Icons.place_rounded,
                  title: 'Location',
                  body: 'Asked later, when you start map-based territory runs.',
                  muted: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Shared rounded hero image with a gradient blend and an overlaid Oswald
/// headline + subtitle — the visual language used across onboarding & auth.
class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.image,
    required this.headline,
    required this.subtitle,
    this.height = 250,
  });

  final String image;
  final String headline;
  final String subtitle;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
      child: SizedBox(
        height: height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Image.asset(image, fit: BoxFit.cover, cacheWidth: 1080),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Color(0x11000000),
                      Color(0x00000000),
                      Color(0x99000000),
                      Color(0xE0000000),
                    ],
                    stops: <double>[0.0, 0.35, 0.75, 1.0],
                  ),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(headline,
                        style: AppTypography.heading(size: 27, color: Colors.white)
                            .copyWith(height: 1.03)),
                    const SizedBox(height: 6),
                    Text(subtitle,
                        style: AppTypography.body(size: 13, color: Colors.white)
                            .copyWith(color: Colors.white.withValues(alpha: 0.82))),
                  ],
                ),
              ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.15, end: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermRow extends StatelessWidget {
  const _PermRow({
    required this.icon,
    required this.title,
    required this.body,
    this.muted = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color accent = muted ? cs.onSurfaceVariant : FitBoxColors.red;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: accent, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: AppTypography.title(size: 16, color: cs.onSurface)),
              const SizedBox(height: 2),
              Text(body,
                  style: AppTypography.body(size: 13, color: cs.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }
}
