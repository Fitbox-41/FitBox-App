/// Central configuration for backend endpoints.
class AppConfig {
  const AppConfig._();

  /// Website backend — handles authentication for the shared customer account
  /// (email/password + OTP), and issues the JWT the app stores.
  static const String websiteApiBase = 'https://fit-box-sports-website-efns.vercel.app';

  /// App backend (wallet / runs / territory), deployed on Vercel. Override at
  /// build time with --dart-define=APP_API_BASE=https://...
  static const String appApiBase = String.fromEnvironment(
    'APP_API_BASE',
    defaultValue: 'https://fit-box-app.vercel.app',
  );
}
