import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';
import 'models/app_user.dart';

/// Talks to the website's `/api/auth/*` endpoints — the shared login used by
/// both the website and the app.
class AuthRepository {
  AuthRepository(this._dio, this._appDio);

  final Dio _dio;

  /// Account *deletion* lives on the app backend, not the website: only that
  /// side knows about runs, territory, the points ledger and notifications, and
  /// deleting the login while that data survived would make the app's
  /// data-safety promise untrue.
  final Dio _appDio;

  /// Step 1 of sign-up: emails a one-time code to the address.
  Future<void> requestSignupOtp(String email) async {
    await _dio.post('/auth/pre-register', data: {'email': email});
  }

  /// Step 2 of sign-up: verifies the code and creates the account.
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required String otp,
  }) async {
    final res = await _dio.post('/auth/register', data: {
      'name': name,
      'email': email,
      'password': password,
      'otp': otp,
    });
    return AuthResult.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  /// Google sign-in: creates the account if new (no password) or signs in an
  /// existing user, using the website's `/api/auth/google` endpoint.
  Future<AuthResult> googleLogin({
    required String name,
    required String email,
  }) async {
    final res = await _dio.post('/auth/google', data: {
      'name': name,
      'email': email,
    });
    return AuthResult.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  /// Email + password login.
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final res = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return AuthResult.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  /// Fetches the current user using the stored token (used on app start).
  Future<AppUser> profile() async {
    final res = await _dio.get('/auth/profile');
    return AppUser.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  /// Sets/updates the signed-in user's password (requires a valid token).
  Future<void> updatePassword(String newPassword) async {
    await _dio.put('/auth/password', data: {'password': newPassword});
  }

  /// Step 1 of a forgotten-password reset: emails a 6-digit code.
  Future<void> requestPasswordResetOtp(String email) async {
    await _dio.post('/auth/forgot-password-otp', data: {'email': email});
  }

  /// Step 2 of reset: verifies the code and returns a session (token + user),
  /// after which the new password can be set via [updatePassword].
  Future<AuthResult> verifyResetOtp({
    required String email,
    required String otp,
  }) async {
    final res = await _dio.post('/auth/verify-reset-otp', data: {
      'email': email,
      'otp': otp,
    });
    return AuthResult.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  /// Permanently deletes the signed-in account and every trace of it this app
  /// stores. Throws on failure so the caller can say so rather than pretending.
  Future<void> deleteAccount() async {
    await _appDio.delete<dynamic>('/account');
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(websiteDioProvider),
    ref.watch(appDioProvider),
  ),
);
