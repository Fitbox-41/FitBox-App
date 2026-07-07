import 'package:flutter/material.dart';

/// FitBox brand palette.
class FitBoxColors {
  const FitBoxColors._();

  static const Color green = Color(0xFF0B5138);
  static const Color greenLight = Color(0xFF0B7A4B);
  static const Color orange = Color(0xFFFF6B35);
  static const Color credit = Color(0xFF0B7A4B);
  static const Color debit = Color(0xFFB00020);
}

/// Centralised theme so every screen shares one consistent look.
class AppTheme {
  const AppTheme._();

  static ThemeData light() => _base(Brightness.light);
  static ThemeData dark() => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: FitBoxColors.green,
      primary: FitBoxColors.green,
      secondary: FitBoxColors.orange,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );
  }
}
