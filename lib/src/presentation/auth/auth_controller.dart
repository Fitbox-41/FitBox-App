import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth_repository.dart';
import '../../data/models/app_user.dart';
import '../../services/google_auth_service.dart';
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
    return const AuthState(AuthStatus.unknown);
  }

  Future<void> _restoreSession() async {
    try {
      final token = await _storage.readToken();
      if (token == null || token.isEmpty) {
        state = const AuthState(AuthStatus.unauthenticated);
        return;
      }
      final user = await _repo.profile();
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

  /// Verifies the reset code, signs the user in, and sets the new password.
  Future<void> confirmPasswordReset({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final result = await _repo.verifyResetOtp(email: email, otp: otp);
    await _storage.saveToken(result.token);
    await _repo.updatePassword(newPassword);
    state = AuthState(AuthStatus.authenticated, result.user);
  }

  Future<void> logout() async {
    await _storage.clear();
    await _google.signOut();
    state = const AuthState(AuthStatus.unauthenticated);
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
