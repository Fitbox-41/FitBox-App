import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// A premium skeleton loader — a soft sheen sweeps across placeholder blocks
/// while async data loads (replaces bare spinners for a higher-end feel).
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Color base =
        (dark ? Colors.white : Colors.black).withValues(alpha: 0.06);
    final Color highlight =
        (dark ? Colors.white : Colors.black).withValues(alpha: 0.14);

    // Respect "reduce motion" — show the static skeleton without the sweep.
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      if (_c.isAnimating) _c.stop();
      return widget.child;
    }
    if (!_c.isAnimating) _c.repeat();

    return AnimatedBuilder(
      animation: _c,
      builder: (BuildContext context, Widget? child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (Rect bounds) {
            final double t = _c.value * 2 - 1; // -1 → 1
            return LinearGradient(
              begin: Alignment(-1 - t, 0),
              end: Alignment(1 - t, 0),
              colors: <Color>[base, highlight, base],
              stops: const <double>[0.35, 0.5, 0.65],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// A single skeleton block.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.radius = 8,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: (dark ? Colors.white : Colors.black).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// A vertical stack of skeleton "cards" wrapped in the shimmer sweep — a ready
/// loading state for list/dashboard screens.
class SkeletonList extends StatelessWidget {
  const SkeletonList({
    super.key,
    this.count = 5,
    this.itemHeight = 76,
    this.padding = const EdgeInsets.fromLTRB(20, 8, 20, 20),
  });

  final int count;
  final double itemHeight;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer(
      child: ListView.separated(
        padding: padding,
        itemCount: count,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (BuildContext context, int i) => Container(
          height: itemHeight,
          decoration: BoxDecoration(
            color: (dark ? Colors.white : Colors.black).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: FitBoxColors.glassStroke(Theme.of(context).brightness)),
          ),
        ),
      ),
    );
  }
}
