// lib/main.dart
// VERTX — App entry point + routing

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:media_kit/media_kit.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'core/api/api_service.dart';
import 'core/l10n/app_localizations.dart';
import 'features/auth/auth_screen.dart';
import 'features/home/home_screen.dart';
import 'features/series/series_detail_screen.dart';
import 'features/player/player_screen.dart';
import 'features/paywall/paywall_screen.dart';
import 'features/search/search_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/home/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  // Force portrait only — vertical platform
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.black,
  ));

  runApp(const ProviderScope(child: VertxApp()));
}

// ── Router ────────────────────────────────────────────────────
final _api = ApiService();

final _router = GoRouter(
  initialLocation: '/home',
  redirect: (context, state) async {
    final hasToken = await _api.hasToken();
    final isAuth = state.matchedLocation.startsWith('/auth');
    if (!hasToken && !isAuth) return '/auth';
    if (hasToken && isAuth) return '/home';
    return null;
  },
  routes: [
    GoRoute(
      path: '/auth',
      builder: (ctx, state) => const AuthScreen(),
    ),
    ShellRoute(
      builder: (ctx, state, child) => MainShell(child: child),
      routes: [
        GoRoute(path: '/home', builder: (c, s) => const HomeScreen()),
        GoRoute(path: '/search', builder: (c, s) => const SearchScreen()),
        GoRoute(
            path: '/watching',
            builder: (c, s) => const ContinueWatchingScreenImpl()),
        GoRoute(path: '/profile', builder: (c, s) => const ProfileScreen()),
      ],
    ),
    GoRoute(
      path: '/series/:id',
      builder: (ctx, state) => SeriesDetailScreen(
        seriesId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/player/:seriesId',
      builder: (ctx, state) => PlayerScreen(
        seriesId: state.pathParameters['seriesId']!,
        startEpisodeIdx:
            int.tryParse(state.uri.queryParameters['ep'] ?? '0') ?? 0,
      ),
    ),
    GoRoute(
      path: '/paywall/:seriesId',
      builder: (ctx, state) => PaywallScreen(
        seriesId: state.pathParameters['seriesId']!,
      ),
    ),
  ],
);

class VertxApp extends StatelessWidget {
  const VertxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'VERTX',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: _router,

      // Bilingual support
      locale: const Locale('en'), // Default: English
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: [
        AppLocalizations.delegate,
        ...AppLocalizations.supportedLocales
            .map((_) => GlobalMaterialLocalizations.delegate),
      ],
    );
  }
}
