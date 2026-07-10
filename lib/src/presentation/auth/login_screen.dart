import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../services/api_client.dart';
import 'auth_controller.dart';

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
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Image.asset('assets/images/logo_mark.png', width: 150),
                  const SizedBox(height: 16),
                  Text('Welcome back',
                      textAlign: TextAlign.center,
                      style: text.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  Text('Log in to your FitBox account',
                      textAlign: TextAlign.center,
                      style: text.bodyMedium
                          ?.copyWith(color: Theme.of(context).hintColor)),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const <String>[AutofillHints.email],
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
                    textInputAction: TextInputAction.done,
                    autofillHints: const <String>[AutofillHints.password],
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                            _obscure ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Enter your password' : null,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _loading ? null : () => context.push('/reset'),
                      child: const Text('Forgot password?'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50)),
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Log in'),
                  ),
                  if (!kIsWeb) ...<Widget>[
                    const SizedBox(height: 16),
                    Row(
                      children: const <Widget>[
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text('or'),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _loading ? null : _google,
                      icon: const Icon(Icons.g_mobiledata, size: 28),
                      label: const Text('Continue with Google'),
                      style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50)),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Text("Don't have an account?"),
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
      ),
    );
  }
}
