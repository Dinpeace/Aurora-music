import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aurora_music/data/services/aurora_cloud_catalog_service.dart';

void main() {
  test('catalog item parses numeric values safely', () {
    final item = AuroraCatalogItem.fromJson({
      'id': 'one',
      'title': 'Aurora',
      'artist': 'Artist',
      'album': 'Album',
      'genres': ['pop'],
      'durationMs': 180000,
      'artworkUrl': 'https://example.com/art.jpg',
      'provider': 'youtube',
      'providerId': 'yt-one',
      'popularity': 0.8,
    });

    expect(item.id, 'one');
    expect(item.durationMs, 180000);
    expect(item.popularity, closeTo(.8, .0001));
    expect(item.genres, ['pop']);
  });

  test('empty search does not require a network call', () async {
    final service = AuroraCloudCatalogService(dio: Dio());

    expect(await service.search('   '), isEmpty);
  });

  test('missing optional fields are handled safely', () {
    final item = AuroraCatalogItem.fromJson({
      'id': 'one',
      'title': 'Song',
    });

    expect(item.id, 'one');
    expect(item.artist, isEmpty);
    expect(item.streamUrl, isNull);
    expect(item.genres, isEmpty);
  });
}
