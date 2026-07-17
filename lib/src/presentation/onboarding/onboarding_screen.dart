import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../widgets/glass.dart';
import 'onboarding_controller.dart';

class _Slide {
  const _Slide(this.icon, this.title, this.body);
  final IconData icon;
  final String title;
  final String body;
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  static const List<_Slide> _slides = <_Slide>[
    _Slide(Icons.directions_run, 'Track every run',
        'Log your distance, pace, and route with precision built for the modern athlete.'),
    _Slide(Icons.map_outlined, 'Capture territory',
        'Turn your city into a game — claim zones as you run and defend your ground.'),
    _Slide(Icons.redeem, 'Earn & spend',
        'Convert activity into points and spend them in the FitBox store.'),
  ];

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
    if (_page < _slides.length - 1) {
      _controller.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('Skip'),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (int i) => setState(() => _page = i),
                itemCount: _slides.length,
                itemBuilder: (BuildContext context, int i) {
                  final _Slide s = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Center(child: _RingIcon(icon: s.icon)),
                        const SizedBox(height: 56),
                        Text(s.title, style: AppText.kinetic(context, size: 40)),
                        const SizedBox(height: 12),
                        Text(s.body,
                            style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontSize: 16,
                                height: 1.5)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(_slides.length, (int i) {
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
            Padding(
              padding: const EdgeInsets.all(24),
              child: GlowButton(
                label: _page == _slides.length - 1 ? 'Get started' : 'Continue',
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingIcon extends StatelessWidget {
  const _RingIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          for (final double d in <double>[220, 180])
            Container(
              width: d,
              height: d,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: FitBoxColors.red.withValues(alpha: 0.25)),
              ),
            ),
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.onSurface.withValues(alpha: 0.06),
              border:
                  Border.all(color: cs.onSurface.withValues(alpha: 0.12)),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: FitBoxColors.red.withValues(alpha: 0.3),
                  blurRadius: 40,
                  spreadRadius: -10,
                ),
              ],
            ),
            child: Icon(icon, color: FitBoxColors.red, size: 56),
          ),
        ],
      ),
    );
  }
}
