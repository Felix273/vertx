# VERTX Flutter App — Setup Guide
# Kenya-first vertical streaming platform

## Prerequisites
- Flutter 3.19+ (stable channel)
- Dart 3.3+
- Android Studio or Xcode

## Quick Start

```bash
# 1. Install dependencies
flutter pub get

# 2. Configure API URL
# Edit lib/core/constants.dart → apiBaseUrl
# Or pass at build time:
# flutter run --dart-define=API_URL=https://api.vertx.co

# 3. Run (development)
flutter run

# 4. Build release
# Android:
flutter build apk --release --dart-define=API_URL=https://api.vertx.co
# or AAB for Play Store:
flutter build appbundle --release --dart-define=API_URL=https://api.vertx.co

# iOS:
flutter build ipa --release --dart-define=API_URL=https://api.vertx.co
```

## App Structure

```
lib/
├── main.dart                    # Entry + GoRouter setup
├── core/
│   ├── api/api_service.dart     # Dio client, all API calls
│   ├── theme/app_theme.dart     # Dark cinematic theme
│   ├── l10n/app_localizations.dart  # Swahili + English strings
│   └── constants.dart           # Pricing, keys, config
├── shared/
│   ├── models/models.dart       # Dart data models
│   └── widgets/widgets.dart     # Reusable UI components
└── features/
    ├── auth/auth_screen.dart    # Login + register
    ├── home/
    │   ├── home_screen.dart     # Feed with featured banner
    │   └── main_shell.dart      # Bottom nav shell
    ├── series/
    │   └── series_detail_screen.dart
    ├── player/
    │   └── player_screen.dart   # ← Vertical swipe player
    ├── paywall/
    │   └── paywall_screen.dart  # M-Pesa subscription/purchase
    ├── search/search_screen.dart
    └── profile/profile_screen.dart
```

## Key Features

### Vertical Swipe Player
- PageView.builder with Axis.vertical
- VideoPlayerController per episode
- Pre-loads next episode while current plays
- Auto-advance on completion
- Saves progress every 10 seconds
- Full-screen immersive mode

### M-Pesa Paywall (Sandbox)
- KES 99/week or KES 299/month
- Phone number input with +254 prefix
- STK Push via backend Daraja API
- Waiting screen while user enters PIN
- Switches to production via MPESA_ENV=production in Django .env

### Bilingual
- Default locale: Swahili (sw)
- Fallback: English (en)
- All UI strings in app_localizations.dart
- Add more languages by extending the class

## Pricing (KES)
| Plan    | Price    |
|---------|----------|
| Weekly  | KES 99   |
| Monthly | KES 299  |

These are set in `lib/core/constants.dart` and mirrored in the Django backend `apps/payments/views.py → PLAN_PRICES`.

## Switching M-Pesa to Production
In your Django `.env`:
```
MPESA_ENV=production
MPESA_CONSUMER_KEY=<your-production-key>
MPESA_CONSUMER_SECRET=<your-production-secret>
MPESA_SHORTCODE=<your-till-or-paybill>
MPESA_PASSKEY=<your-production-passkey>
```
No Flutter code changes required.
