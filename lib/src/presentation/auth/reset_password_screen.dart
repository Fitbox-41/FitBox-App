import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../services/api_client.dart';
import '../widgets/glass.dart';
import '../widgets/motion.dart';
import '../widgets/responsive_form_body.dart';
import 'auth_controller.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

enum _Step { email, reset }

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _emailKey = GlobalKey<FormState>();
  final _resetKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _otp = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();

  _Step _step = _Step.email;
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _otp.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _error(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(messageFromError(e))));
  }

  Future<void> _sendCode() async {
    if (!_emailKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .requestPasswordReset(_email.text.trim());
      if (!mounted) return;
      setState(() => _step = _Step.reset);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('We emailed you a reset code.')),
      );
    } catch (e) {
      _error(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reset() async {
    if (!_resetKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider.notifier).confirmPasswordReset(
            email: _email.text.trim(),
            otp: _otp.text.trim(),
            newPassword: _next.text,
          );
      // Success: signed in with the new password → router redirects to home.
    } catch (e) {
      _error(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: SafeArea(
        child: ResponsiveFormBody(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 4),
              const Center(
                  child: LogoBadge(width: 56, heroTag: 'fitbox-logo')),
              const SizedBox(height: 18),
              _step == _Step.email ? _emailForm() : _resetForm(),
            ].revealStagger(),
          ),
        ),
      ),
    );
  }

  Widget _emailForm() {
    return Form(
      key: _emailKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('Reset password',
              textAlign: TextAlign.center,
              style: AppText.kinetic(context, size: 24)),
          const SizedBox(height: 4),
          Text(
            "Enter your account email and we'll send you a 6-digit code.",
            textAlign: TextAlign.center,
            style: AppTypography.body(
                size: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.mail_outline),
            ),
            validator: (v) {
              final value = (v ?? '').trim();
              if (value.isEmpty) return 'Enter your email';
              if (!value.contains('@') || !value.contains('.')) {
                return 'Enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 22),
          GlowButton(
            label: 'Send code',
            loading: _loading,
            onPressed: _loading ? null : _sendCode,
          ),
        ],
      ),
    );
  }

  Widget _resetForm() {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Form(
      key: _resetKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: FitBoxColors.red.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_reset,
                  color: FitBoxColors.red, size: 32),
            ),
          ),
          const SizedBox(height: 14),
          Text('Enter code + new password',
              textAlign: TextAlign.center,
              style: AppTypography.heading(size: 22, color: cs.onSurface)),
          const SizedBox(height: 4),
          Text('Sent to ${_email.text.trim()}',
              textAlign: TextAlign.center,
              style: AppTypography.body(size: 13, color: cs.onSurfaceVariant)),
          const SizedBox(height: 22),
          TextFormField(
            controller: _otp,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            style: AppText.data(context, size: 24).copyWith(letterSpacing: 6),
            decoration: const InputDecoration(
              counterText: '',
              labelText: '6-digit code',
            ),
            validator: (v) =>
                (v ?? '').trim().length != 6 ? 'Enter the 6-digit code' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _next,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'New password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon:
                    Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: (v) =>
                (v == null || v.length < 6) ? 'At least 6 characters' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _confirm,
            obscureText: _obscure,
            decoration: const InputDecoration(
              labelText: 'Confirm new password',
              prefixIcon: Icon(Icons.lock_outline),
            ),
            validator: (v) =>
                v != _next.text ? 'Passwords do not match' : null,
          ),
          const SizedBox(height: 22),
          GlowButton(
            label: 'Reset password',
            loading: _loading,
            onPressed: _loading ? null : _reset,
          ),
          TextButton(
            onPressed: _loading ? null : _sendCode,
            child: const Text('Resend code'),
          ),
        ],
      ),
    );
  }
}
