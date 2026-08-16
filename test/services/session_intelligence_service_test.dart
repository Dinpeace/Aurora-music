import 'package:flutter_test/flutter_test.dart';
import 'package:aurora_music/data/models/online/online_song.dart';
import 'package:aurora_music/data/models/song.dart';
import 'package:aurora_music/data/services/session_intelligence_service.dart';

Song _song(String id, String title, String artist) {
  return Song(
    id: id,
    title: title,
    artist: artist,
    album: 'Test Album',
    audioUrl: '/music/$id.mp3',
    duration: const Duration(minutes: 3),
  );
}

OnlineSong _online(String id, String title, String artist) {
  return OnlineSong(
    id: id,
    title: title,
    artist: artist,
    album: 'Test Album',
    artwork: '',
    streamUrl: '',
    duration: const Duration(minutes: 3),
  );
}

void main() {
  group('SessionIntelligenceService', () {
    test('records plays and exposes artist/session signals', () {
      final service = SessionIntelligenceService();
      service.recordPlay(_song('1', 'First', 'Aurora'));
      service.recordPlay(_song('2', 'Second', 'Aurora'));

      expect(service.playedCount, 2);
      expect(service.lastSongId, '2');
      expect(service.artistPlayCounts['aurora'], 2);
      expect(service.sessionSongIds, containsAll(<String>['1', '2']));
    });

    test('skips reduce candidate score and mark it rejected', () {
      final service = SessionIntelligenceService();
      service.recordPlay(_song('1', 'Skipped', 'Aurora'));
      final before = service.scoreOnlineSong(_online('1', 'Skipped', 'Aurora'));

      service.recordSkip('1');

      final after = service.scoreOnlineSong(_online('1', 'Skipped', 'Aurora'));
      expect(after, lessThan(before));
      expect(service.rejectedSongIds, contains('1'));
    });

    test('ranks candidates with the current artist preference', () {
      final service = SessionIntelligenceService();
      service.recordPlay(_song('1', 'Played', 'Aurora'));

      final ranked = service.rankOnlineSongs(<OnlineSong>[
        _online('2', 'Other', 'Other Artist'),
        _online('3', 'Similar', 'Aurora'),
      ]);

      expect(ranked.first.id, '3');
    });
  });
}
