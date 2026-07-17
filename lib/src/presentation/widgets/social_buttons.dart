import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// "Continue with Google" — hairline pill with the real multi-colour Google "G".
/// Used on mobile (web uses the official rendered GIS button instead).
class GoogleButton extends StatelessWidget {
  const GoogleButton({super.key, required this.onPressed, this.enabled = true});

  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return _SocialPill(
      onPressed: enabled ? onPressed : null,
      background: Colors.transparent,
      borderColor: cs.onSurface.withValues(alpha: 0.18),
      foreground: cs.onSurface,
      icon: SvgPicture.asset('assets/icons/google_g.svg', width: 22, height: 22),
      label: 'Continue with Google',
    );
  }
}

/// "Continue with Apple" — Apple's black button with the white Apple mark.
/// (Required on iOS when third-party sign-in is offered.)
class AppleButton extends StatelessWidget {
  const AppleButton({super.key, required this.onPressed, this.enabled = true});

  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return _SocialPill(
      onPressed: enabled ? onPressed : null,
      background: Colors.black,
      borderColor: Colors.white.withValues(alpha: 0.14),
      foreground: Colors.white,
      icon: SvgPicture.asset(
        'assets/icons/apple_logo.svg',
        width: 20,
        height: 20,
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      ),
      label: 'Continue with Apple',
    );
  }
}

class _SocialPill extends StatelessWidget {
  const _SocialPill({
    required this.onPressed,
    required this.background,
    required this.borderColor,
    required this.foreground,
    required this.icon,
    required this.label,
  });

  final VoidCallback? onPressed;
  final Color background;
  final Color borderColor;
  final Color foreground;
  final Widget icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: Material(
        color: background,
        shape: StadiumBorder(side: BorderSide(color: borderColor)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              icon,
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
