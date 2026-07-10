import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/config/app_config.dart';

/// Google account details returned after a successful sign-in.
class GoogleAccount {
  const GoogleAccount({required this.name, required this.email});
  final String name;
  final String email;
}

/// Wraps `google_sign_in` (v7). Google verifies the email, so no OTP is needed.
class GoogleAuthService {
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance
        .initialize(serverClientId: AppConfig.googleServerClientId);
    _initialized = true;
  }

  /// Web initialisation: the browser flow uses `clientId` (the OAuth Web client)
  /// and delivers results through [accountStream].
  Future<void> initializeForWeb() async {
    if (_initialized) return;
    await GoogleSignIn.instance
        .initialize(clientId: AppConfig.googleServerClientId);
    _initialized = true;
  }

  /// Stream of accounts from Google sign-in events (used on web with the
  /// rendered button).
  Stream<GoogleAccount> accountStream() {
    return GoogleSignIn.instance.authenticationEvents
        .where((event) => event is GoogleSignInAuthenticationEventSignIn)
        .map((event) => (event as GoogleSignInAuthenticationEventSignIn).user)
        .map((user) {
      final String? display = user.displayName?.trim();
      final String name = (display != null && display.isNotEmpty)
          ? display
          : user.email.split('@').first;
      return GoogleAccount(name: name, email: user.email);
    });
  }

  /// Prompts the user to pick a Google account. Returns the account, or `null`
  /// if the user cancels. Throws for genuine errors.
  Future<GoogleAccount?> signIn() async {
    await _ensureInitialized();
    final GoogleSignIn signIn = GoogleSignIn.instance;
    if (!signIn.supportsAuthenticate()) {
      throw Exception('Google sign-in is not available on this device.');
    }
    try {
      final GoogleSignInAccount account = await signIn.authenticate();
      final String? display = account.displayName?.trim();
      final String name = (display != null && display.isNotEmpty)
          ? display
          : account.email.split('@').first;
      return GoogleAccount(name: name, email: account.email);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {/* ignore */}
  }
}

final googleAuthServiceProvider =
    Provider<GoogleAuthService>((ref) => GoogleAuthService());
