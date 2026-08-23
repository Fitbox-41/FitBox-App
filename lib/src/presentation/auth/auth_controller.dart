import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth_repository.dart';
import '../../data/models/app_user.dart';
import '../../services/google_auth_service.dart';
import '../../services/push_service.dart';
import '../../services/secure_storage.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState(this.status, [this.user]);

  final AuthStatus status;
  final AppUser? user;

  bool get isAuthenticated => status == AuthStatus.authenticated;
}

/// Holds the app-wide authentication state. On start it tries to restore a
/// session from the stored token; screens call [login]/[register]/[logout].
class AuthController extends Notifier<AuthState> {
  late final AuthRepository _repo;
  late final SecureStorage _storage;
  late final GoogleAuthService _google;

  @override
  AuthState build() {
    _repo = ref.read(authRepositoryProvider);
    _storage = ref.read(secureStorageProvider);
    _google = ref.read(googleAuthServiceProvider);
    _restoreSession();
    if (kIsWeb) _setupGoogleWeb();
    return const AuthState(AuthStatus.unknown);
  }

  /// Web Google sign-in is driven by a rendered button; results come on a
  /// stream. Fully deferred and guarded so it can never throw during build or
  /// block the app from leaving the splash screen.
  void _setupGoogleWeb() {
    unawaited(Future<void>(() async {
      try {
        await _google.initializeForWeb();
        _google.accountStream().listen((account) async {
          ref.read(googleSigningInProvider.notifier).set(true);
          try {
            final result = await _repo.googleLogin(
                name: account.name, email: account.email);
            await _storage.saveToken(result.token);
            state = AuthState(AuthStatus.authenticated, result.user);
          } catch (_) {
            /* ignore; user can retry */
          } finally {
            try {
              ref.read(googleSigningInProvider.notifier).set(false);
            } catch (_) {}
          }
        });
      } catch (_) {/* google web unavailable; email login still works */}
    }));
  }

  Future<void> _restoreSession() async {
    try {
      // Never let a slow/hanging storage or network read keep the app on the
      // splash screen: fall back to signed-out after a short timeout.
      final token = await _storage
          .readToken()
          .timeout(const Duration(seconds: 6), onTimeout: () => null);
      if (token == null || token.isEmpty) {
        state = const AuthState(AuthStatus.unauthenticated);
        return;
      }
      final user =
          await _repo.profile().timeout(const Duration(seconds: 12));
      state = AuthState(AuthStatus.authenticated, user);
    } catch (_) {
      try {
        await _storage.clear();
      } catch (_) {/* ignore */}
      state = const AuthState(AuthStatus.unauthenticated);
    }
  }

  Future<void> login({required String email, required String password}) async {
    final result = await _repo.login(email: email, password: password);
    await _storage.saveToken(result.token);
    state = AuthState(AuthStatus.authenticated, result.user);
  }

  Future<void> requestSignupOtp(String email) => _repo.requestSignupOtp(email);

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String otp,
  }) async {
    final result = await _repo.register(
      name: name,
      email: email,
      password: password,
      otp: otp,
    );
    await _storage.saveToken(result.token);
    state = AuthState(AuthStatus.authenticated, result.user);
  }

  /// Google sign-in. Returns false if the user cancels the picker.
  Future<bool> signInWithGoogle() async {
    final account = await _google.signIn();
    if (account == null) return false;
    final result =
        await _repo.googleLogin(name: account.name, email: account.email);
    await _storage.saveToken(result.token);
    state = AuthState(AuthStatus.authenticated, result.user);
    return true;
  }

  /// Sign in with Apple — not wired yet. When enabled this will use the
  /// `sign_in_with_apple` package (iOS native + Android/web via the web flow)
  /// and post the identity token to the website's Apple auth endpoint, exactly
  /// mirroring [signInWithGoogle]. Kept as one hook so enabling it is a small,
  /// single-place change for both platforms.
  Future<bool> signInWithApple() async {
    throw UnimplementedError('Sign in with Apple is coming soon.');
  }

  /// Sets or changes the password. If [currentPassword] is provided it is
  /// verified first via the login endpoint (Google users setting one for the
  /// first time can leave it empty). Auth state is unchanged.
  Future<void> changePassword({
    String? currentPassword,
    required String newPassword,
  }) async {
    final email = state.user?.email;
    if (email == null) throw Exception('You are not signed in.');
    if (currentPassword != null && currentPassword.isNotEmpty) {
      try {
        await _repo.login(email: email, password: currentPassword);
      } on DioException catch (e) {
        if (e.response?.statusCode == 401) {
          throw Exception('Current password is incorrect.');
        }
        rethrow;
      }
    }
    await _repo.updatePassword(newPassword);
  }

  Future<void> requestPasswordReset(String email) =>
      _repo.requestPasswordResetOtp(email);

  /// Verifies the reset code and sets the new password, then signs the user
  /// back OUT so they return to the login screen and sign in with the new
  /// password (the token is used only to authorize the password update).
  Future<void> confirmPasswordReset({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final result = await _repo.verifyResetOtp(email: email, otp: otp);
    await _storage.saveToken(result.token); // needed to call updatePassword
    await _repo.updatePassword(newPassword);
    await _detachDevice();
    await _storage.clear(); // don't keep them signed in
    state = const AuthState(AuthStatus.unauthenticated);
  }

  /// Detaches this device from the account being signed out of.
  ///
  /// A push token identifies a phone, and the backend delivers a user's pushes
  /// to every token on their record — so a token left behind on the previous
  /// account means that account's notifications keep arriving on a phone
  /// somebody else is now signed in on. Must run while the JWT is still
  /// present, because /push/unregister is authenticated.
  ///
  /// Best-effort: the server also reassigns the token on the next /push/register,
  /// so failing here (offline, expired token) is recoverable rather than fatal.
  Future<void> _detachDevice() async {
    try {
      await ref.read(pushServiceProvider).unregister();
    } catch (_) {/* the next register reassigns it */}
  }

  Future<void> logout() async {
    await _detachDevice();
    await _storage.clear();
    // Update state first so the router redirects immediately; Google sign-out
    // is best-effort and must never block the logout.
    state = const AuthState(AuthStatus.unauthenticated);
    await _google.signOut();
  }

  /// Permanently deletes the account and everything the app stored for it.
  ///
  /// The server call has to happen while the token is still on the device, so
  /// this signs out only once deletion has actually succeeded. If it fails the
  /// session is left intact and the caller shows the error — silently signing
  /// someone out of an account that still exists would look like it worked.
  Future<void> deleteAccount() async {
    await _repo.deleteAccount();
    await _detachDevice();
    await _storage.clear();
    state = const AuthState(AuthStatus.unauthenticated);
    await _google.signOut();
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

/// Whether the user is exploring as a **guest** (no account). Guests can browse
/// the app, but account actions (wallet, syncing, profile) prompt a sign-in.
/// Cleared automatically once the user authenticates (see the router).
class GuestMode extends Notifier<bool> {
  @override
  bool build() => false;

  void enter() => state = true;
  void exit() => state = false;
}

final guestModeProvider = NotifierProvider<GuestMode, bool>(GuestMode.new);

/// True while a web Google sign-in is being completed (network round-trip),
/// so the UI can show a brief loading overlay.
class GoogleSigningIn extends Notifier<bool> {
  @override
  bool build() => false;
  void set(bool value) => state = value;
}

final googleSigningInProvider =
    NotifierProvider<GoogleSigningIn, bool>(GoogleSigningIn.new);
