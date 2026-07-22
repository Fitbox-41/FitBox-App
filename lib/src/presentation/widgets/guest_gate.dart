import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import 'glass.dart';

/// Shown in place of account-only content when the user is browsing as a guest.
/// A tasteful, on-brand nudge to sign in — never a dead end.
class GuestGate extends StatelessWidget {
  const GuestGate({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 120),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: <Color>[
                  FitBoxColors.red.withValues(alpha: 0.28),
                  FitBoxColors.red.withValues(alpha: 0.06),
                ]),
                border: Border.all(color: FitBoxColors.red.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, color: FitBoxColors.red, size: 40),
            ),
            const SizedBox(height: 20),
            Text(title, style: AppText.kinetic(context, size: 24)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: AppTypography.body(size: 14, color: cs.onSurfaceVariant)),
            const SizedBox(height: 24),
            GlowButton(
              label: 'Sign In',
              icon: Icons.arrow_forward,
              onPressed: () => context.push('/signin'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => context.push('/signup'),
              child: const Text('Create an account'),
            ),
          ],
        ),
      ),
    );
  }
}
