import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../services/api_client.dart';
import '../widgets/glass.dart';
import 'auth_controller.dart';
import 'google_web_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider.notifier).login(
            email: _email.text.trim(),
            password: _password.text,
          );
      // Navigation is handled by the router's auth redirect.
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(messageFromError(e))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _google() async {
    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider.notifier).signInWithGoogle();
      // Success → router redirect; cancel → stay here.
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(messageFromError(e))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool signingIn = ref.watch(googleSigningInProvider);
    return Scaffold(
      body: Stack(
        children: <Widget>[
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const LogoBadge(width: 190, heroTag: 'fitbox-logo'),
                      const SizedBox(height: 28),
                      GlassCard(
                        radius: 28,
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Text('Welcome\nback',
                                  style: AppText.kinetic(context, size: 44)),
                              const SizedBox(height: 8),
                              Text('Enter your details to access your dashboard.',
                                  style: text.bodyMedium
                                      ?.copyWith(color: cs.onSurfaceVariant)),
                              const SizedBox(height: 24),
                              TextFormField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const <String>[
                                  AutofillHints.email
                                ],
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.mail_outline),
                                ),
                                validator: (v) {
                                  final value = (v ?? '').trim();
                                  if (value.isEmpty) return 'Enter your email';
                                  if (!value.contains('@') ||
                                      !value.contains('.')) {
                                    return 'Enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _password,
                                obscureText: _obscure,
                                textInputAction: TextInputAction.done,
                                autofillHints: const <String>[
                                  AutofillHints.password
                                ],
                                onFieldSubmitted: (_) => _submit(),
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscure
                                        ? Icons.visibility_off
                                        : Icons.visibility),
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                  ),
                                ),
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'Enter your password'
                                    : null,
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _loading
                                      ? null
                                      : () => context.push('/reset'),
                                  child: const Text('Forgot password?'),
                                ),
                              ),
                              const SizedBox(height: 8),
                              GlowButton(
                                label: 'Log in',
                                icon: Icons.arrow_forward,
                                loading: _loading,
                                onPressed: _loading ? null : _submit,
                              ),
                              const SizedBox(height: 18),
                              Row(
                                children: <Widget>[
                                  const Expanded(child: Divider()),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    child: Text('OR',
                                        style:
                                            AppText.labelCaps(context, size: 12)),
                                  ),
                                  const Expanded(child: Divider()),
                                ],
                              ),
                              const SizedBox(height: 18),
                              if (kIsWeb)
                                Center(child: googleSignInWebButton())
                              else
                                OutlinedButton.icon(
                                  onPressed: _loading ? null : _google,
                                  icon: const Icon(Icons.g_mobiledata, size: 28),
                                  label: const Text('Continue with Google'),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Flexible(
                            child: Text("Don't have an account?",
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: cs.onSurfaceVariant)),
                          ),
                          TextButton(
                            onPressed:
                                _loading ? null : () => context.push('/signup'),
                            child: const Text('Sign up'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (signingIn)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x99000000),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}
