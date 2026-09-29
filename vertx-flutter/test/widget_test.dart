import 'package:flutter_test/flutter_test.dart';
import 'package:vertx/shared/models/models.dart';

void main() {
  test('series and access models parse API responses', () {
    final series = Series.fromJson({
      'id': 'series-1',
      'title': 'Test Series',
      'description': 'A test story',
      'genre': 'drama',
      'thumbnail_url': '',
      'trailer_url': '',
      'price': '99.00',
      'is_free': false,
      'producer_name': 'Test Studio',
      'episode_count': 1,
      'episodes': [
        {
          'id': 'episode-1',
          'episode_number': 1,
          'title': 'Episode One',
          'description': '',
          'duration_secs': 60,
          'thumbnail_url': '',
        },
      ],
    });
    final access = AccessStatus.fromJson({
      'has_access': false,
      'reason': 'no_access',
      'options': {'subscribe': true, 'purchase': true, 'price': '99.00'},
    });

    expect(series.title, 'Test Series');
    expect(series.episodes.single.durationDisplay, '1:00');
    expect(access.canSubscribe, isTrue);
    expect(access.canPurchase, isTrue);
    expect(access.purchasePrice, '99.00');
  });

  test('continue-watching records use server-provided duration', () {
    final record = WatchRecord.fromJson({
      'id': 'watch-1',
      'series_id': 'series-1',
      'series_title': 'Test Series',
      'episode_num': 1,
      'episode_title': 'Episode One',
      'thumbnail': '',
      'episode_duration_secs': 240,
      'progress_secs': 120,
      'completed': false,
      'watched_at': '2026-01-01T00:00:00Z',
    });

    expect(record.episodeDurationSecs, 240);
    expect(record.progressSecs / record.episodeDurationSecs, 0.5);
  });
}
