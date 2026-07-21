import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';

/// App-wide gradient backdrop (light/dark) with a soft red glow, giving glass
/// surfaces depth to refract.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
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
                    .withValues(alpha: dark ? 0.14 : 0.08),
                size: 280),
          ),
          Positioned(
            bottom: -140,
            left: -110,
            child: _Glow(
                color: FitBoxColors.red
                    .withValues(alpha: dark ? 0.07 : 0.05),
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
/// light/dark. iOS-style materiality (backdrop blur + top-left hairline).
class GlassCard extends StatefulWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 24,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final VoidCallback? onTap;

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final Brightness b = Theme.of(context).brightness;
    final BorderRadius br = BorderRadius.circular(widget.radius);

    final Widget card = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: br,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: FitBoxColors.glassFill(b),
              borderRadius: br,
              border: Border.all(color: FitBoxColors.glassStroke(b)),
            ),
            child: Padding(padding: widget.padding, child: widget.child),
          ),
        ),
      ),
    );

    if (widget.onTap == null) return card;

    // Tappable cards get a springy press + haptic (Apple-style feedback).
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap!();
      },
      child: AnimatedScale(
        scale: _down ? 0.98 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: card,
      ),
    );
  }
}

/// Signature red pill button with a soft red glow underneath — the primary CTA
/// ("Start a run", "Log in"). Springy press.
class GlowButton extends StatefulWidget {
  const GlowButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 56,
    this.expand = true,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  final bool expand;
  final bool loading;

  @override
  State<GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<GlowButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onPressed != null && !widget.loading;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapUp: enabled ? (_) => setState(() => _down = false) : null,
      onTapCancel: enabled ? () => setState(() => _down = false) : null,
      onTap: enabled
          ? () {
              HapticFeedback.mediumImpact();
              widget.onPressed!();
            }
          : null,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          height: widget.height,
          width: widget.expand ? double.infinity : null,
          padding: widget.expand
              ? null
              : const EdgeInsets.symmetric(horizontal: 28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: <Color>[FitBoxColors.red, FitBoxColors.redDark],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            // Adidas-style sharp rectangle (was a pill).
            borderRadius: BorderRadius.circular(6),
            boxShadow: enabled
                ? <BoxShadow>[
                    BoxShadow(
                      color: FitBoxColors.red.withValues(alpha: 0.3),
                      blurRadius: 22,
                      spreadRadius: -3,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: widget.loading
              ? const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.4, color: Colors.white),
                  ),
                )
              : Row(
                  mainAxisSize:
                      widget.expand ? MainAxisSize.max : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    if (widget.icon != null) ...<Widget>[
                      Icon(widget.icon, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                    ],
                    Text(
                      widget.label.toUpperCase(),
                      style: AppTypography.button(color: Colors.white, size: 15),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// The real FitBox logo, **blended** onto the screen (no white chip): the
/// light-on-dark mark on dark themes, the dark-on-light mark on light themes,
/// over a soft red glow so it sits premium on the gradient.
class LogoBadge extends StatelessWidget {
  const LogoBadge({super.key, this.width = 180, this.heroTag, this.glow = true});

  final double width;
  final Object? heroTag;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final String asset = dark
        ? 'assets/images/logo_mark_dark.png' // "Fit" in white — for dark bg
        : 'assets/images/logo_mark.png'; // "Fit" in charcoal — for light bg

    Widget badge = Image.asset(asset, width: width, fit: BoxFit.contain);

    if (glow) {
      badge = Stack(
        alignment: Alignment.center,
        children: <Widget>[
          IgnorePointer(
            child: Container(
              width: width * 0.9,
              height: width * 0.45,
              decoration: BoxDecoration(
                gradient: RadialGradient(colors: <Color>[
                  FitBoxColors.red.withValues(alpha: dark ? 0.22 : 0.12),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          badge,
        ],
      );
    }

    if (heroTag != null) {
      badge = Hero(
        tag: heroTag!,
        flightShuttleBuilder: (_, _, _, _, toContext) =>
            (toContext.widget as Hero).child,
        child: Material(type: MaterialType.transparency, child: badge),
      );
    }
    return badge;
  }
}
