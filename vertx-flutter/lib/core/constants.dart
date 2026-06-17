// lib/core/constants.dart
// VERTX — App-wide constants

class AppConstants {
  AppConstants._();

  // ── API ───────────────────────────────────────────────────
  static const String apiBaseUrl =
      String.fromEnvironment('API_URL', defaultValue: 'https://api.vertx.co');

  // ── Pricing (KES) ─────────────────────────────────────────
  static const int weeklyPriceKes = 99;
  static const int monthlyPriceKes = 299;
  static const String currency = 'KES';

  // ── Storage keys ──────────────────────────────────────────
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserId = 'user_id';
  static const String keyUserRole = 'user_role';

  // ── Content ───────────────────────────────────────────────
  static const int maxSwipeEpisodes = 50;
  static const Duration progressSaveInterval = Duration(seconds: 10);

  // ── UI ────────────────────────────────────────────────────
  static const double playerAspectRatio = 9 / 16; // vertical
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animNormal = Duration(milliseconds: 350);
  static const Duration animSlow = Duration(milliseconds: 500);
}
