import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import 'secure_storage.dart';

/// Dio client for the website API (auth + shared customer data). Automatically
/// attaches the stored JWT as a Bearer token when present.
Dio _websiteDio(SecureStorage storage) {
  final dio = Dio(
    BaseOptions(
      baseUrl: '${AppConfig.websiteApiBase}/api',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      contentType: Headers.jsonContentType,
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.readToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ),
  );
  return dio;
}

final websiteDioProvider = Provider<Dio>(
  (ref) => _websiteDio(ref.watch(secureStorageProvider)),
);

/// Dio client for the app's own backend (wallet / runs / territory). Attaches
/// the same stored JWT, which the app backend verifies with the shared secret.
Dio _appDio(SecureStorage storage) {
  final dio = Dio(
    BaseOptions(
      baseUrl: '${AppConfig.appApiBase}/api',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      contentType: Headers.jsonContentType,
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.readToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ),
  );
  return dio;
}

final appDioProvider = Provider<Dio>(
  (ref) => _appDio(ref.watch(secureStorageProvider)),
);

/// Extracts a human-readable message from a failed request.
String messageFromError(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return 'Network problem. Check your connection and try again.';
    }
  }
  return 'Something went wrong. Please try again.';
}
