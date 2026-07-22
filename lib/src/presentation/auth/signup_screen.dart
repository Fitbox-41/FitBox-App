import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../services/api_client.dart';
import '../widgets/glass.dart';
import '../widgets/responsive_form_body.dart';
import '../widgets/social_buttons.dart';
import 'auth_controller.dart';
import 'google_web_button.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

enum _Step { details, verify }

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _detailsKey = GlobalKey<FormState>();
  final _otpKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _otp = TextEditingController();

  _Step _step = _Step.details;
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _otp.dispose();
    super.dispose();
  }

  void _showError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(messageFromError(e))));
  }

  Future<void> _sendCode() async {
    if (!_detailsKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .requestSignupOtp(_email.text.trim());
      if (!mounted) return;
      setState(() => _step = _Step.verify);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('We emailed you a 6-digit code.')),
      );
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _google() async {
    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider.notifier).signInWithGoogle();
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createAccount() async {
    if (!_otpKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider.notifier).register(
            name: _name.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
            otp: _otp.text.trim(),
          );
      // Router redirect takes over on success.
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: Stack(
        children: <Widget>[
          SafeArea(
            child: ResponsiveFormBody(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SizedBox(height: 8),
                  const Center(
                      child: LogoBadge(width: 64, heroTag: 'fitbox-logo')),
                  const SizedBox(height: 16),
                  _step == _Step.details ? _detailsForm() : _verifyForm(),
                ],
              ),
            ),
          ),
          if (Navigator.of(context).canPop())
            Positioned(
              top: MediaQuery.paddingOf(context).top + 4,
              left: 4,
              child: BackButton(color: cs.onSurface),
            ),
        ],
      ),
    );
  }

  Widget _detailsForm() {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Form(
      key: _detailsKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('Create account',
              textAlign: TextAlign.center,
              style: AppText.kinetic(context, size: 24)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Full name',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
          ),
          const SizedBox(height: 11),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
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
          const SizedBox(height: 11),
          TextFormField(
            controller: _password,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon:
                    Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: (v) => (v == null || v.length < 6)
                ? 'At least 6 characters'
                : null,
          ),
          const SizedBox(height: 16),
          GlowButton(
            label: 'Send verification code',
            icon: Icons.arrow_forward,
            loading: _loading,
            onPressed: _loading ? null : _sendCode,
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('OR',
                    style: AppTypography.label(
                        size: 11, color: cs.onSurfaceVariant)),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 12),
          if (kIsWeb)
            Center(child: googleSignInWebButton())
          else
            GoogleButton(enabled: !_loading, onPressed: _google),
          const SizedBox(height: 10),
          AppleButton(
            enabled: !_loading,
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text('Sign in with Apple is coming soon.'),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text('Already have an account?'),
              TextButton(
                onPressed: _loading ? null : () => context.pop(),
                child: const Text('Sign in'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _verifyForm() {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Form(
      key: _otpKey,
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
              child: const Icon(Icons.mark_email_read_outlined,
                  color: FitBoxColors.red, size: 32),
            ),
          ),
          const SizedBox(height: 14),
          Text('Enter the code',
              textAlign: TextAlign.center,
              style: AppTypography.heading(size: 24, color: cs.onSurface)),
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
            style: AppText.data(context, size: 26).copyWith(letterSpacing: 8),
            decoration: const InputDecoration(
              counterText: '',
              hintText: '••••••',
            ),
            validator: (v) {
              final value = (v ?? '').trim();
              if (value.length != 6) return 'Enter the 6-digit code';
              return null;
            },
          ),
          const SizedBox(height: 20),
          GlowButton(
            label: 'Create account',
            icon: Icons.check_rounded,
            loading: _loading,
            onPressed: _loading ? null : _createAccount,
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: _loading ? null : _sendCode,
            child: const Text('Resend code'),
          ),
          TextButton(
            onPressed:
                _loading ? null : () => setState(() => _step = _Step.details),
            child: const Text('Change details'),
          ),
        ],
      ),
    );
  }
}
