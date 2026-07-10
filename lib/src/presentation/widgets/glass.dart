import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// App-wide gradient backdrop (light/dark) with a soft red glow, giving glass
/// surfaces depth to refract.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dark
              ? const <Color>[FitBoxColors.bgTopDark, FitBoxColors.bgBottomDark]
              : const <Color>[FitBoxColors.bgTopLight, FitBoxColors.bgBottomLight],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Positioned(
            top: -120,
            right: -90,
            child: _Glow(
                color: FitBoxColors.red
                    .withValues(alpha: dark ? 0.22 : 0.12),
                size: 280),
          ),
          Positioned(
            bottom: -140,
            left: -110,
            child: _Glow(
                color: FitBoxColors.red
                    .withValues(alpha: dark ? 0.10 : 0.06),
                size: 320),
          ),
          child,
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: <Color>[color, Colors.transparent]),
        ),
      ),
    );
  }
}

/// A frosted-glass card: blurred, translucent, hairline-bordered — adapts to
/// light/dark.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 22,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Brightness b = Theme.of(context).brightness;
    final BorderRadius br = BorderRadius.circular(radius);
    Widget content = Padding(padding: padding, child: child);
    if (onTap != null) {
      content = InkWell(borderRadius: br, onTap: onTap, child: content);
    }
    return ClipRRect(
      borderRadius: br,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: FitBoxColors.glassFill(b),
            borderRadius: br,
            border: Border.all(color: FitBoxColors.glassStroke(b)),
          ),
          child: content,
        ),
      ),
    );
  }
}

/// The FitBox logo on a crisp white rounded "chip" so it reads well on any
/// theme (no per-pixel recolouring).
class LogoBadge extends StatelessWidget {
  const LogoBadge({super.key, this.width = 140});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: width * 0.12, vertical: width * 0.09),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(width * 0.18),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Image.asset('assets/images/logo_mark.png', width: width),
    );
  }
}
