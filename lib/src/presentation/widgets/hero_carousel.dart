import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// One slide of the auth hero carousel.
class HeroSlide {
  const HeroSlide({
    required this.image,
    required this.heading,
    required this.caption,
  });

  final String image; // asset path
  final String heading;
  final String caption;
}

/// Full-bleed hero image carousel for the auth landing (Strava / Nike / Adidas
/// style): auto-scrolls every 3s, pauses while dragging, resumes after, loops
/// infinitely, animated page dots, and an overlaid heading + caption with a
/// dark gradient scrim for readability.
class HeroCarousel extends StatefulWidget {
  const HeroCarousel({
    super.key,
    required this.slides,
    this.bottomInset = 24,
  });

  final List<HeroSlide> slides;

  /// Space reserved at the bottom for an overlapping auth sheet — the heading,
  /// caption and dots are laid out just above this line.
  final double bottomInset;

  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> {
  // Start far from 0 so the carousel can loop both directions.
  static const int _base = 10000;
  late final PageController _controller =
      PageController(initialPage: _base);
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !_controller.hasClients) return;
      _controller.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  void _stop() => _timer?.cancel();

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int n = widget.slides.length;
    return Listener(
      // Pause auto-scroll while the user is dragging; resume after.
      onPointerDown: (_) => _stop(),
      onPointerUp: (_) => _start(),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          PageView.builder(
            controller: _controller,
            onPageChanged: (int i) => setState(() => _page = i % n),
            itemBuilder: (BuildContext context, int i) {
              final HeroSlide s = widget.slides[i % n];
              return Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Image.asset(s.image, fit: BoxFit.cover, cacheWidth: 1080),
                  // Dark scrim: top (status bar) + strong at the bottom for text.
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          Color(0x55000000),
                          Color(0x00000000),
                          Color(0x22000000),
                          Color(0x99000000),
                        ],
                        stops: <double>[0.0, 0.3, 0.62, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: widget.bottomInset + 30,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          s.heading.toUpperCase(),
                          style: AppTypography.heading(size: 27, color: Colors.white)
                              .copyWith(height: 1.02),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          s.caption,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.body(size: 13.5, color: Colors.white)
                              .copyWith(color: Colors.white.withValues(alpha: 0.82)),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          // Page dots — sit just above the auth sheet.
          Positioned(
            left: 0,
            right: 0,
            bottom: widget.bottomInset + 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(n, (int i) {
                final bool active = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 20 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: active
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
