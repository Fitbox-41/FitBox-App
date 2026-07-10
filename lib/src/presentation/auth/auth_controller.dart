import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth_repository.dart';
import '../../data/models/app_user.dart';
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

  @override
  AuthState build() {
    _repo = ref.read(authRepositoryProvider);
    _storage = ref.read(secureStorageProvider);
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

  Future<void> logout() async {
    await _storage.clear();
    state = const AuthState(AuthStatus.unauthenticated);
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
