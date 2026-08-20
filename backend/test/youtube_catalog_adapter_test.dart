import 'package:test/test.dart';

import 'package:aurora_cloud_foundation/src/youtube_catalog_adapter.dart';

void main() {
  test('parses a YouTube search result without needing the network', () {
    final result = YoutubeVideoResult.fromJson({
      'id': {'kind': 'youtube#video', 'videoId': 'abc123'},
      'snippet': {
        'title': 'Aurora Song',
        'channelTitle': 'Example Artist',
        'description': 'Example description',
        'thumbnails': {
          'high': {'url': 'https://i.ytimg.com/vi/abc123/hqdefault.jpg'}
        }
      }
    });

    expect(result.videoId, 'abc123');
    expect(result.title, 'Aurora Song');
    expect(result.channelTitle, 'Example Artist');
    expect(result.watchUrl, 'https://www.youtube.com/watch?v=abc123');
    expect(
      result.embedUrl,
      'https://www.youtube.com/embed/abc123',
    );
  });

  test('invalid search result produces an empty video ID', () {
    final result = YoutubeVideoResult.fromJson({
      'id': {},
      'snippet': {'title': 'Missing ID'},
    });

    expect(result.videoId, isEmpty);
  });
}
