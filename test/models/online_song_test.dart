import 'package:flutter_test/flutter_test.dart';
import 'package:aurora_music/data/models/online/online_song.dart';

void main() {
  group('OnlineSong', () {
    test('parses common JSON fields and duration', () {
      final song = OnlineSong.fromJson({
        'videoId': 'abc123',
        'name': 'Night Drive',
        'author': 'Aurora Artist',
        'albumName': 'After Dark',
        'thumbnail': 'https://example.com/art.jpg',
        'stream_url': 'https://example.com/audio',
        'duration': '3:42',
      });

      expect(song.id, 'abc123');
      expect(song.title, 'Night Drive');
      expect(song.artist, 'Aurora Artist');
      expect(song.album, 'After Dark');
      expect(song.duration, const Duration(minutes: 3, seconds: 42));
    });

    test('falls back safely for missing fields', () {
      final song = OnlineSong.fromJson(const <String, dynamic>{});

      expect(song.title, 'Unknown Title');
      expect(song.artist, 'Unknown Artist');
      expect(song.album, 'YouTube');
      expect(song.duration, Duration.zero);
    });
  });
}
