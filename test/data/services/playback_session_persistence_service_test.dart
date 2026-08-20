import 'package:flutter_test/flutter_test.dart';

import 'package:aurora_music/data/models/song.dart';
import 'package:aurora_music/data/services/playback_session_persistence_service.dart';

void main() {
  Song song({
    String id = 'song-1',
    String title = 'Aurora',
  }) =>
      Song(
        id: id,
        title: title,
        artist: 'Artist',
        album: 'Album',
        artwork: 'artwork',
        audioUrl: '/music/$id.mp3',
        duration: const Duration(minutes: 3),
        favorite: true,
      );

  test('snapshot preserves the playback model', () {
    final original = PlaybackSessionSnapshot(
      currentSong: song(),
      queue: [song(), song(id: 'song-2', title: 'Second')],
      position: const Duration(seconds: 42),
      shuffleEnabled: true,
      repeatMode: 'all',
      crossfadeDuration: const Duration(seconds: 5),
    );

    expect(original.currentSong!.id, 'song-1');
    expect(original.queue.length, 2);
    expect(original.position.inSeconds, 42);
    expect(original.shuffleEnabled, isTrue);
    expect(original.repeatMode, 'all');
    expect(original.crossfadeDuration.inSeconds, 5);
  });

  test('empty queue is a valid session state', () {
    const snapshot = PlaybackSessionSnapshot(
      currentSong: null,
      queue: [],
      position: Duration.zero,
      shuffleEnabled: false,
      repeatMode: 'off',
      crossfadeDuration: Duration.zero,
    );

    expect(snapshot.currentSong, isNull);
    expect(snapshot.queue, isEmpty);
  });

  test('song fields needed for restoration are present', () {
    final value = song();

    expect(value.id, isNotEmpty);
    expect(value.audioUrl, isNotEmpty);
    expect(value.duration, greaterThan(Duration.zero));
  });
}
