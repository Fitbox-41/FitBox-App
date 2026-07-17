import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// FitBox brand + glass palette ("Aerostride Kinetic"), working in light and dark.
class FitBoxColors {
  const FitBoxColors._();

  // Brand
  static const Color red = Color(0xFFE31E24);
  static const Color redDark = Color(0xFFB3141A);
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
      ? charcoal.withValues(alpha: 0.55)
      : Colors.white.withValues(alpha: 0.6);
  static Color glassStroke(Brightness b) => b == Brightness.dark
      ? Colors.white.withValues(alpha: 0.14)
      : Colors.white.withValues(alpha: 0.7);
}

/// Platform font policy (locked): **Android → Inter** (Google Fonts),
/// **iOS/macOS → SF Pro** (the system font). Everything in the app resolves its
/// typeface through [platformFont], so both platforms feel native automatically.
bool get _isApplePlatform =>
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.macOS;

/// Returns a text style in the platform's font: SF Pro on Apple, Inter elsewhere.
TextStyle platformFont({
  double? size,
  FontWeight? weight,
  FontStyle? style,
  double? letterSpacing,
  double? height,
  Color? color,
  bool display = false,
}) {
  if (_isApplePlatform) {
    // Apple system font (San Francisco). If the exact name doesn't resolve, iOS
    // still falls back to the system font, which is SF — so this is safe.
    return TextStyle(
      fontFamily: display ? '.SF Pro Display' : '.SF Pro Text',
      fontFamilyFallback: const <String>['.SF Pro Display', '.SF Pro Text'],
      fontSize: size,
      fontWeight: weight,
      fontStyle: style,
      letterSpacing: letterSpacing,
      height: height,
      color: color,
    );
  }
  return GoogleFonts.inter(
    fontSize: size,
    fontWeight: weight,
    fontStyle: style,
    letterSpacing: letterSpacing,
    height: height,
    color: color,
  );
}

/// Named text styles built on the platform font — the "kinetic" italic headers
/// and the bold data numerals used across the app.
class AppText {
  const AppText._();

  /// Forward-leaning italic header — the brand voice (platform font, bold).
  static TextStyle kinetic(
    BuildContext context, {
    double size = 32,
    Color? color,
    FontWeight weight = FontWeight.w800,
  }) =>
      platformFont(
        size: size,
        weight: weight,
        style: FontStyle.italic,
        height: 1.05,
        letterSpacing: -0.5,
        display: true,
        color: color ?? Theme.of(context).colorScheme.onSurface,
      );

  /// Big data numerals — steps, timers, points (platform font, bold).
  static TextStyle data(
    BuildContext context, {
    double size = 42,
    Color? color,
    bool italic = false,
    FontWeight weight = FontWeight.w700,
  }) =>
      platformFont(
        size: size,
        weight: weight,
        style: italic ? FontStyle.italic : FontStyle.normal,
        height: 1.0,
        letterSpacing: -1,
        display: true,
        color: color ?? Theme.of(context).colorScheme.onSurface,
      );

  /// Uppercase technical label with wide tracking (platform font).
  static TextStyle labelCaps(
    BuildContext context, {
    double size = 12,
    Color? color,
  }) =>
      platformFont(
        size: size,
        weight: FontWeight.w600,
        letterSpacing: 1.2,
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

    // Font policy: Android = Inter, iOS = SF Pro (system). Body uses the
    // platform font; headlines are the platform font in bold kinetic italic.
    final TextTheme base = (brightness == Brightness.dark
            ? ThemeData.dark()
            : ThemeData.light())
        .textTheme;
    // On Apple keep the system (SF Pro) baseline; elsewhere apply Inter.
    final TextTheme body = _isApplePlatform
        ? base.apply(
            fontFamily: '.SF Pro Text',
            fontFamilyFallback: const <String>['.SF Pro Display'],
          )
        : GoogleFonts.interTextTheme(base);
    TextStyle kinetic(TextStyle? s) => platformFont(
          size: s?.fontSize,
          weight: FontWeight.w800,
          style: FontStyle.italic,
          letterSpacing: -0.5,
          height: 1.05,
          display: true,
          color: s?.color,
        );
    final TextTheme textTheme = body.copyWith(
      displayLarge: kinetic(base.displayLarge),
      displayMedium: kinetic(base.displayMedium),
      displaySmall: kinetic(base.displaySmall),
      headlineLarge: kinetic(base.headlineLarge),
      headlineMedium: kinetic(base.headlineMedium),
      headlineSmall: kinetic(base.headlineSmall),
      titleLarge: platformFont(
        size: base.titleLarge?.fontSize,
        weight: FontWeight.w700,
        color: base.titleLarge?.color,
      ),
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
        // Kinetic italic AppBar titles (platform font).
        titleTextStyle: platformFont(
          size: 24,
          weight: FontWeight.w800,
          style: FontStyle.italic,
          letterSpacing: -0.5,
          display: true,
          color: onSurface,
        ),
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
          // Fully rounded pill.
          shape: const StadiumBorder(),
          textStyle: platformFont(
            weight: FontWeight.w700,
            size: 15,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          minimumSize: const Size.fromHeight(54),
          side: BorderSide(color: onSurface.withValues(alpha: 0.18)),
          shape: const StadiumBorder(),
          textStyle: platformFont(
            weight: FontWeight.w600,
            size: 15,
          ),
        ),
      ),
    );
  }
}
