// lib/core/api/api_service.dart
// VERTX — Dio API client with JWT auto-refresh

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants.dart';
import '../../shared/models/models.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    _init();
  }

  late final Dio _dio;
  final _storage = const FlutterSecureStorage();
  bool _refreshing = false;

  void _init() {
    _dio = Dio(BaseOptions(
      baseUrl: '${AppConstants.apiBaseUrl}/api',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    // ── Attach token ───────────────────────────────────────
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: AppConstants.keyAccessToken);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401 && !_refreshing) {
          _refreshing = true;
          try {
            final newToken = await _refreshAccessToken();
            if (newToken != null) {
              final opts = error.requestOptions;
              opts.headers['Authorization'] = 'Bearer $newToken';
              final resp = await _dio.fetch(opts);
              handler.resolve(resp);
              return;
            }
          } catch (_) {
            await clearTokens();
          } finally {
            _refreshing = false;
          }
        }
        handler.next(error);
      },
    ));
  }

  Future<String?> _refreshAccessToken() async {
    final refresh = await _storage.read(key: AppConstants.keyRefreshToken);
    if (refresh == null) return null;

    final resp = await Dio().post(
      '${AppConstants.apiBaseUrl}/api/auth/token/refresh/',
      data: {'refresh': refresh},
    );
    final newAccess = resp.data['access'] as String;
    await _storage.write(key: AppConstants.keyAccessToken, value: newAccess);
    return newAccess;
  }

  // ── Token management ──────────────────────────────────────
  Future<void> saveTokens(String access, String refresh) async {
    await _storage.write(key: AppConstants.keyAccessToken, value: access);
    await _storage.write(key: AppConstants.keyRefreshToken, value: refresh);
  }

  Future<void> clearTokens() async {
    await _storage.deleteAll();
  }

  Future<bool> hasToken() async {
    final t = await _storage.read(key: AppConstants.keyAccessToken);
    return t != null;
  }

  // ── Auth endpoints ────────────────────────────────────────
  Future<Map<String, dynamic>> login(String email, String password) async {
    final r = await _dio.post('/auth/login/', data: {
      'email': email,
      'password': password,
    });
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String fullName,
    required String password,
    required String password2,
  }) async {
    final r = await _dio.post('/auth/register/viewer/', data: {
      'email': email,
      'full_name': fullName,
      'password': password,
      'password2': password2,
    });
    return r.data as Map<String, dynamic>;
  }

  Future<User> getMe() async {
    final r = await _dio.get('/auth/me/');
    return User.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> logout(String refreshToken) async {
    await _dio.post('/auth/logout/', data: {'refresh': refreshToken});
  }

  // ── Content ───────────────────────────────────────────────
  Future<HomeFeed> getHomeFeed() async {
    final r = await _dio.get('/home/');
    return HomeFeed.fromJson(r.data as Map<String, dynamic>);
  }

  Future<List<Series>> browseSeries({String? genre}) async {
    final r = await _dio.get('/series/', queryParameters: {
      if (genre != null) 'genre': genre,
    });
    final data = r.data as Map<String, dynamic>;
    final items = (data['results'] ?? data) as List<dynamic>;
    return items
        .map((e) => Series.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Series> getSeriesDetail(String id) async {
    final r = await _dio.get('/series/$id/');
    return Series.fromJson(r.data as Map<String, dynamic>);
  }

  Future<List<Series>> searchSeries(String query) async {
    final r = await _dio.get('/series/', queryParameters: {'search': query});
    final data = r.data as Map<String, dynamic>;
    final items = (data['results'] ?? data) as List<dynamic>;
    return items
        .map((e) => Series.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AccessStatus> checkAccess(String seriesId) async {
    final r = await _dio.get('/series/$seriesId/access/');
    return AccessStatus.fromJson(r.data as Map<String, dynamic>);
  }

  // ── Streaming ─────────────────────────────────────────────
  Future<Map<String, dynamic>> getStreamUrl(String episodeId) async {
    final r = await _dio.get('/episodes/$episodeId/stream/');
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getProgress(String episodeId) async {
    final r = await _dio.get('/episodes/$episodeId/progress/');
    return r.data as Map<String, dynamic>;
  }

  Future<void> saveProgress(String episodeId, int progressSecs,
      {bool completed = false}) async {
    await _dio.post('/episodes/$episodeId/progress/', data: {
      'progress_secs': progressSecs,
      'completed': completed,
    });
  }

  Future<List<WatchRecord>> getContinueWatching() async {
    final r = await _dio.get('/continue-watching/');
    final data = r.data as Map<String, dynamic>;
    final items = (data['results'] ?? data) as List<dynamic>;
    return items
        .map((e) => WatchRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Payments ──────────────────────────────────────────────
  Future<Map<String, dynamic>> initiateSubscription({
    required String plan,
    required String phone,
  }) async {
    final r = await _dio.post('/payments/subscribe/', data: {
      'plan': plan,
      'provider': 'mpesa',
      'metadata': {'phone': phone},
    });
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> purchaseSeries({
    required String seriesId,
    required String phone,
  }) async {
    final r = await _dio.post('/payments/purchase/$seriesId/', data: {
      'provider': 'mpesa',
      'metadata': {'phone': phone},
    });
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getSubscriptionStatus() async {
    final r = await _dio.get('/payments/subscription/');
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getPaymentStatus(String paymentId) async {
    final r = await _dio.get('/payments/status/$paymentId/');
    return r.data as Map<String, dynamic>;
  }
}
