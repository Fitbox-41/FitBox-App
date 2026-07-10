import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../services/api_client.dart';
import 'auth_controller.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _step == _Step.details ? _detailsForm() : _verifyForm(),
        ),
      ),
    );
  }

  Widget _detailsForm() {
    return Form(
      key: _detailsKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Full name',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.mail_outline),
              border: OutlineInputBorder(),
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
          const SizedBox(height: 14),
          TextFormField(
            controller: _password,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              border: const OutlineInputBorder(),
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
          const SizedBox(height: 22),
          FilledButton(
            onPressed: _loading ? null : _sendCode,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Send verification code'),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text('Already have an account?'),
              TextButton(
                onPressed: _loading ? null : () => context.pop(),
                child: const Text('Log in'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _verifyForm() {
    final text = Theme.of(context).textTheme;
    return Form(
      key: _otpKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Icon(Icons.mark_email_read_outlined,
              color: FitBoxColors.green, size: 48),
          const SizedBox(height: 12),
          Text('Enter the code',
              textAlign: TextAlign.center,
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          Text('Sent to ${_email.text.trim()}',
              textAlign: TextAlign.center,
              style:
                  text.bodySmall?.copyWith(color: Theme.of(context).hintColor)),
          const SizedBox(height: 20),
          TextFormField(
            controller: _otp,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            style: const TextStyle(fontSize: 22, letterSpacing: 8),
            decoration: const InputDecoration(
              counterText: '',
              hintText: '••••••',
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              final value = (v ?? '').trim();
              if (value.length != 6) return 'Enter the 6-digit code';
              return null;
            },
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _loading ? null : _createAccount,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Create account'),
          ),
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
