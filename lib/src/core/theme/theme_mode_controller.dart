import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/secure_storage.dart';

/// Holds the app's ThemeMode (system/light/dark), persisted across launches.
/// Defaults to following the system theme.
class ThemeModeController extends Notifier<ThemeMode> {
  late final SecureStorage _storage;

  @override
  ThemeMode build() {
    _storage = ref.read(secureStorageProvider);
    _load();
    return ThemeMode.system;
  }

  Future<void> _load() async {
    try {
      state = _parse(await _storage.readThemeMode());
    } catch (_) {/* keep system */}
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    try {
      await _storage.saveThemeMode(mode.name);
    } catch (_) {/* ignore */}
  }

  static ThemeMode _parse(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);
