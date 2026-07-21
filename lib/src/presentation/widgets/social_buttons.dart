import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_theme.dart';

/// "Continue with Google" — rectangular frosted-glass button with the real
/// multi-colour Google "G". (Web uses the official rendered GIS button instead.)
class GoogleButton extends StatelessWidget {
  const GoogleButton({super.key, required this.onPressed, this.enabled = true});

  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return _GlassSocialButton(
      onPressed: enabled ? onPressed : null,
      icon: SvgPicture.asset('assets/icons/google_g.svg', width: 22, height: 22),
      label: 'Continue with Google',
    );
  }
}

/// "Continue with Apple" — rectangular frosted-glass button with the Apple mark
/// (tinted to the current text colour so it works on light or dark glass).
class AppleButton extends StatelessWidget {
  const AppleButton({super.key, required this.onPressed, this.enabled = true});

  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final Color fg = Theme.of(context).colorScheme.onSurface;
    return _GlassSocialButton(
      onPressed: enabled ? onPressed : null,
      icon: SvgPicture.asset(
        'assets/icons/apple_logo.svg',
        width: 20,
        height: 20,
        colorFilter: ColorFilter.mode(fg, BlendMode.srcIn),
      ),
      label: 'Sign in with Apple',
    );
  }
}

/// Rectangular frosted-glass button (blur + translucent fill + hairline border),
/// Adidas-style sharp corners, with an Oswald uppercase label. Theme-aware, so
/// it looks right on a light or dark surface.
class _GlassSocialButton extends StatelessWidget {
  const _GlassSocialButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  final VoidCallback? onPressed;
  final Widget icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final Brightness b = Theme.of(context).brightness;
    final Color fg = Theme.of(context).colorScheme.onSurface;
    final BorderRadius radius = BorderRadius.circular(6);

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Material(
          color: FitBoxColors.glassFill(b),
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(color: FitBoxColors.glassStroke(b)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed == null
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    onPressed!();
                  },
            child: SizedBox(
              height: 54,
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  icon,
                  const SizedBox(width: 12),
                  Text(
                    label.toUpperCase(),
                    style: AppTypography.button(color: fg, size: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
