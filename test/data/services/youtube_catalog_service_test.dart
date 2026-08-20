import 'package:flutter_test/flutter_test.dart';

import 'package:aurora_music/data/services/youtube_catalog_service.dart';

void main() {
  test('YouTube catalog item preserves official playback URLs', () {
    final item = YoutubeCatalogItem.fromJson({
      'videoId': 'abc123',
      'title': 'Aurora',
      'channelTitle': 'Artist',
      'description': 'Description',
      'thumbnailUrl': 'https://i.ytimg.com/example.jpg',
      'watchUrl': 'https://www.youtube.com/watch?v=abc123',
      'embedUrl': 'https://www.youtube.com/embed/abc123',
    });

    expect(item.videoId, 'abc123');
    expect(item.title, 'Aurora');
    expect(
      item.watchUrl,
      'https://www.youtube.com/watch?v=abc123',
    );
    expect(
      item.embedUrl,
      'https://www.youtube.com/embed/abc123',
    );
  });

  test('empty video IDs can be filtered by the service', () {
    final item = YoutubeCatalogItem.fromJson({
      'videoId': '',
      'title': 'Invalid',
    });

    expect(item.videoId, isEmpty);
  });
}
