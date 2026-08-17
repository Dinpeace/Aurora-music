import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aurora_music/data/models/song.dart';
import 'package:aurora_music/data/services/listening_history_service.dart';

void main() {
  Song song(String id) {
    return Song(
      id: id,
      title: 'Song $id',
      artist: 'Aurora',
      album: 'Album',
      audioUrl: '/music/$id.mp3',
      duration: const Duration(minutes: 3),
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('records and persists listening history', () async {
    final first = ListeningHistoryService();
    await first.initialize();

    await first.recordPlay(
      song: song('one'),
      position: const Duration(seconds: 150),
    );

    final second = ListeningHistoryService();
    await second.initialize();

    expect(second.entries, hasLength(1));
    expect(second.entries.first.song.id, 'one');
    expect(second.entries.first.playCount, 1);
    expect(second.entries.first.position.inSeconds, 150);
  });

  test('increments play and skip counts for the same song', () async {
    final service = ListeningHistoryService();
    await service.initialize();

    await service.recordPlay(song: song('one'));
    await service.recordSkip(
      song: song('one'),
      position: const Duration(seconds: 20),
    );

    expect(service.entries.first.playCount, 2);
    expect(service.entries.first.skipCount, 1);
  });

  test('keeps the newest entries within the configured limit', () async {
    final service = ListeningHistoryService(maxEntries: 2);
    await service.initialize();

    await service.recordPlay(song: song('one'));
    await Future<void>.delayed(const Duration(milliseconds: 1));
    await service.recordPlay(song: song('two'));
    await Future<void>.delayed(const Duration(milliseconds: 1));
    await service.recordPlay(song: song('three'));

    expect(service.entries, hasLength(2));
    expect(service.entries.first.song.id, 'three');
  });

  test('clear removes all stored history', () async {
    final service = ListeningHistoryService();
    await service.initialize();
    await service.recordPlay(song: song('one'));

    await service.clear();

    expect(service.entries, isEmpty);
  });
}
