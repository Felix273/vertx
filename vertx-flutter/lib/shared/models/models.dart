// lib/shared/models/models.dart
// VERTX — Dart data models matching Django API responses

class User {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final String createdAt;

  const User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: j['id'] as String,
        email: j['email'] as String,
        fullName: j['full_name'] as String,
        role: j['role'] as String,
        createdAt: j['created_at'] as String,
      );

  bool get isViewer => role == 'viewer';
  bool get isProducer => role == 'producer';
}

class Series {
  final String id;
  final String title;
  final String description;
  final String genre;
  final String thumbnailUrl;
  final String trailerUrl;
  final String price;
  final bool isFree;
  final String producerName;
  final int episodeCount;
  final String? publishedAt;
  final List<Episode> episodes;

  const Series({
    required this.id,
    required this.title,
    required this.description,
    required this.genre,
    required this.thumbnailUrl,
    required this.trailerUrl,
    required this.price,
    required this.isFree,
    required this.producerName,
    required this.episodeCount,
    this.publishedAt,
    this.episodes = const [],
  });

  factory Series.fromJson(Map<String, dynamic> j) => Series(
        id: j['id'] as String,
        title: j['title'] as String,
        description: j['description'] as String,
        genre: j['genre'] as String,
        thumbnailUrl: j['thumbnail_url'] as String? ?? '',
        trailerUrl: j['trailer_url'] as String? ?? '',
        price: j['price'] as String? ?? '0',
        isFree: j['is_free'] as bool? ?? false,
        producerName: j['producer_name'] as String? ?? '',
        episodeCount: j['episode_count'] as int? ?? 0,
        publishedAt: j['published_at'] as String?,
        episodes: (j['episodes'] as List<dynamic>?)
                ?.map((e) => Episode.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  double get priceDouble => double.tryParse(price) ?? 0.0;
  bool get isPurchasable => priceDouble > 0;
}

class Episode {
  final String id;
  final int episodeNumber;
  final String title;
  final String description;
  final String videoUrl;
  final int durationSecs;
  final String thumbnailUrl;

  const Episode({
    required this.id,
    required this.episodeNumber,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.durationSecs,
    required this.thumbnailUrl,
  });

  factory Episode.fromJson(Map<String, dynamic> j) => Episode(
        id: j['id'] as String,
        episodeNumber: j['episode_number'] as int,
        title: j['title'] as String,
        description: j['description'] as String? ?? '',
        videoUrl: j['video_url'] as String? ?? '',
        durationSecs: j['duration_secs'] as int? ?? 0,
        thumbnailUrl: j['thumbnail_url'] as String? ?? '',
      );

  String get durationDisplay {
    final m = durationSecs ~/ 60;
    final s = durationSecs % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

class AccessStatus {
  final bool hasAccess;
  final String reason;
  final Map<String, dynamic>? options;

  const AccessStatus({
    required this.hasAccess,
    required this.reason,
    this.options,
  });

  factory AccessStatus.fromJson(Map<String, dynamic> j) => AccessStatus(
        hasAccess: j['has_access'] as bool,
        reason: j['reason'] as String,
        options: j['options'] as Map<String, dynamic>?,
      );

  bool get canSubscribe => options?['subscribe'] == true;
  bool get canPurchase => options?['purchase'] == true;
  String get purchasePrice => options?['price'] as String? ?? '0';
}

class WatchRecord {
  final String id;
  final String seriesId;
  final String seriesTitle;
  final int episodeNum;
  final String episodeTitle;
  final String thumbnail;
  final int episodeDurationSecs;
  final int progressSecs;
  final bool completed;
  final String watchedAt;

  const WatchRecord({
    required this.id,
    required this.seriesId,
    required this.seriesTitle,
    required this.episodeNum,
    required this.episodeTitle,
    required this.thumbnail,
    required this.episodeDurationSecs,
    required this.progressSecs,
    required this.completed,
    required this.watchedAt,
  });

  factory WatchRecord.fromJson(Map<String, dynamic> j) => WatchRecord(
        id: j['id'] as String,
        seriesId: j['series_id'] as String,
        seriesTitle: j['series_title'] as String,
        episodeNum: j['episode_num'] as int,
        episodeTitle: j['episode_title'] as String,
        thumbnail: j['thumbnail'] as String? ?? '',
        episodeDurationSecs: j['episode_duration_secs'] as int? ?? 0,
        progressSecs: j['progress_secs'] as int,
        completed: j['completed'] as bool,
        watchedAt: j['watched_at'] as String,
      );
}

class HomeFeed {
  final List<Series> featured;
  final List<Series> newContent;
  final List<Series> free;

  const HomeFeed({
    required this.featured,
    required this.newContent,
    required this.free,
  });

  factory HomeFeed.fromJson(Map<String, dynamic> j) => HomeFeed(
        featured: _parseList(j['featured']),
        newContent: _parseList(j['new']),
        free: _parseList(j['free']),
      );

  static List<Series> _parseList(dynamic data) =>
      (data as List<dynamic>?)
          ?.map((e) => Series.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [];
}

class AuthTokens {
  final String access;
  final String refresh;

  const AuthTokens({required this.access, required this.refresh});

  factory AuthTokens.fromJson(Map<String, dynamic> j) => AuthTokens(
        access: j['access'] as String,
        refresh: j['refresh'] as String,
      );
}
