import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_typography.dart';

// Re-export the typography system so the many files that already
// `import 'app_theme.dart'` keep seeing `platformFont`, `AppTypography`, etc.
export 'app_typography.dart';

/// FitBox brand + glass palette ("Aerostride Kinetic"), working in light and dark.
class FitBoxColors {
  const FitBoxColors._();

  // Brand. `logoRed` is the vivid brand red (kept for the logo); the UI accent
  // `red` is a slightly softer, less-bright tone for a lighter glassmorphism.
  static const Color logoRed = Color(0xFFE31E24);
  static const Color red = Color(0xFFD8474D);
  static const Color redDark = Color(0xFFB03A40);
  static const Color charcoal = Color(0xFF2E2E30);

  // Gradient backdrops — deep "engine bay" black on dark; soft light on light.
  static const Color bgTopDark = Color(0xFF14181C);
  static const Color bgBottomDark = Color(0xFF0A0C0F);
  static const Color bgTopLight = Color(0xFFF2F4F8);
  static const Color bgBottomLight = Color(0xFFE6E9F0);

  // Semantic (wallet ledger, capture/loss)
  static const Color credit = Color(0xFF19A463);
  static const Color debit = Color(0xFFE5484D);

  // Glass tokens per brightness — iOS-style translucent material.
  static Color glassFill(Brightness b) => b == Brightness.dark
      ? charcoal.withValues(alpha: 0.72)
      : Colors.white.withValues(alpha: 0.78);
  static Color glassStroke(Brightness b) => b == Brightness.dark
      ? Colors.white.withValues(alpha: 0.14)
      : Colors.white.withValues(alpha: 0.7);
}

/// Compatibility shim over [AppTypography]. Historically the app used an italic
/// "kinetic" voice; it's now an upright athletic **Oswald** voice. These three
/// helpers keep all existing call sites working while routing through the
/// centralized system. Prefer `AppTypography.*` directly in new code.
class AppText {
  const AppText._();

  /// Header voice → Oswald bold. (The `italic` look is retired.)
  static TextStyle kinetic(
    BuildContext context, {
    double size = 32,
    Color? color,
    FontWeight weight = FontWeight.w700,
  }) =>
      AppTypography.brand(
        size: size,
        weight: weight,
        height: 1.05,
        color: color ?? Theme.of(context).colorScheme.onSurface,
      );

  /// Big numerals → Oswald bold. (`italic` kept for call-site compatibility but
  /// ignored — Oswald reads athletic upright.)
  static TextStyle data(
    BuildContext context, {
    double size = 42,
    Color? color,
    bool italic = false,
    FontWeight weight = FontWeight.w700,
  }) =>
      AppTypography.brand(
        size: size,
        weight: weight,
        height: 1.0,
        letterSpacing: -0.3,
        color: color ?? Theme.of(context).colorScheme.onSurface,
      );

  /// Uppercase technical label → Oswald medium, wide tracking.
  static TextStyle labelCaps(
    BuildContext context, {
    double size = 12,
    Color? color,
  }) =>
      AppTypography.brand(
        size: size,
        weight: FontWeight.w500,
        letterSpacing: 1.8,
        color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
      );
}

class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: FitBoxColors.red,
      primary: FitBoxColors.red,
      brightness: brightness,
    );
    final Color onSurface = scheme.onSurface;

    // Body/label slots keep the platform body font (Inter on Android, SF Pro on
    // iOS); display/headline/title slots become Oswald (athletic).
    final TextTheme base = (brightness == Brightness.dark
            ? ThemeData.dark()
            : ThemeData.light())
        .textTheme;
    final TextTheme body = isApplePlatform
        ? base.apply(
            fontFamily: '.SF Pro Text',
            fontFamilyFallback: const <String>['.SF Pro Display'],
          )
        : GoogleFonts.interTextTheme(base);

    TextStyle osw(TextStyle? s, FontWeight weight) => AppTypography.brand(
          size: s?.fontSize,
          weight: weight,
          height: 1.05,
          color: s?.color,
        );

    final TextTheme textTheme = body.copyWith(
      displayLarge: osw(base.displayLarge, FontWeight.w700),
      displayMedium: osw(base.displayMedium, FontWeight.w700),
      displaySmall: osw(base.displaySmall, FontWeight.w700),
      headlineLarge: osw(base.headlineLarge, FontWeight.w700),
      headlineMedium: osw(base.headlineMedium, FontWeight.w700),
      headlineSmall: osw(base.headlineSmall, FontWeight.w700),
      titleLarge: osw(base.titleLarge, FontWeight.w600),
      titleMedium: osw(base.titleMedium, FontWeight.w600),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: Colors.transparent,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        // Athletic Oswald screen titles.
        titleTextStyle: AppTypography.screenTitle(size: 24, color: onSurface),
        foregroundColor: onSurface,
      ),
      dividerColor: onSurface.withValues(alpha: 0.12),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: onSurface.withValues(alpha: 0.05),
        // Pill inputs to contrast the structured grid.
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: onSurface.withValues(alpha: 0.14)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: FitBoxColors.red, width: 1.5),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: onSurface.withValues(alpha: 0.14)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: FitBoxColors.red,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: AppTypography.button(size: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          minimumSize: const Size.fromHeight(54),
          side: BorderSide(color: onSurface.withValues(alpha: 0.18)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: AppTypography.button(size: 15),
        ),
      ),
    );
  }
}
