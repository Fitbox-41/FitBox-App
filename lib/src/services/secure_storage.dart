import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thin wrapper around platform secure storage for the auth token.
class SecureStorage {
  SecureStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const String _tokenKey = 'jwt_token';
  static const String _themeKey = 'theme_mode';

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> clear() => _storage.delete(key: _tokenKey);

  Future<void> saveThemeMode(String value) =>
      _storage.write(key: _themeKey, value: value);

  Future<String?> readThemeMode() => _storage.read(key: _themeKey);

  // Generic key/value (used e.g. for the daily step baseline).
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  Future<String?> read(String key) => _storage.read(key: key);
}

final secureStorageProvider = Provider<SecureStorage>((ref) => SecureStorage());
