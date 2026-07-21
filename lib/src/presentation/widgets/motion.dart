import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Shared motion language for the app — Apple-like: expressive but calm.
/// One place to tune easing/durations so every screen feels the same.
class AppMotion {
  const AppMotion._();

  /// The signature ease-out (fast start, gentle settle) — `Cubic(0.16,1,0.3,1)`.
  static const Curve expoOut = Cubic(0.16, 1.0, 0.3, 1.0);

  /// A soft spring-ish overshoot for playful reveals.
  static const Curve emphasized = Cubic(0.2, 0.9, 0.2, 1.05);

  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 900);

  /// Staggered entrance for a list of children (fade + rise). Drop-in for any
  /// `children: [...]` — call `.revealStagger()` on the list.
  static const Duration _revealDur = Duration(milliseconds: 340);
}

extension RevealStagger on List<Widget> {
  /// Fade + rise each child in sequence — the app's standard screen entrance.
  List<Widget> revealStagger({
    Duration interval = const Duration(milliseconds: 70),
    double dy = 0.12,
  }) =>
      animate(interval: interval)
          .fadeIn(duration: AppMotion._revealDur, curve: AppMotion.expoOut)
          .slideY(begin: dy, end: 0, curve: AppMotion.expoOut);
}

extension RevealSingle on Widget {
  /// Reveal a single widget (fade + rise).
  Widget reveal({Duration delay = Duration.zero, double dy = 0.12}) =>
      animate(delay: delay)
          .fadeIn(duration: AppMotion._revealDur, curve: AppMotion.expoOut)
          .slideY(begin: dy, end: 0, curve: AppMotion.expoOut);
}

/// Counts a number up from 0 to [value] on first build — for stat tiles, wallet
/// balance, run metrics. Supply a [builder] that formats the interpolated value.
class CountUpText extends StatelessWidget {
  const CountUpText({
    super.key,
    required this.value,
    required this.builder,
    this.duration = AppMotion.slow,
    this.curve = AppMotion.expoOut,
  });

  final double value;
  final Duration duration;
  final Curve curve;
  final Widget Function(BuildContext context, double value) builder;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: duration,
      curve: curve,
      builder: (BuildContext context, double v, _) => builder(context, v),
    );
  }
}
