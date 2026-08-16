import 'package:flutter_test/flutter_test.dart';
import 'package:aurora_music/data/models/listening_history_entry.dart';
import 'package:aurora_music/data/models/online/online_song.dart';
import 'package:aurora_music/data/models/song.dart';
import 'package:aurora_music/data/services/taste_profile_service.dart';

Song _song(String id, String title, String artist, String album) {
  return Song(
    id: id,
    title: title,
    artist: artist,
    album: album,
    audioUrl: '/music/$id.mp3',
    duration: const Duration(minutes: 3),
  );
}

OnlineSong _online(String id, String title, String artist, String album) {
  return OnlineSong(
    id: id,
    title: title,
    artist: artist,
    album: album,
    artwork: '',
    streamUrl: '',
    duration: const Duration(minutes: 3),
  );
}

void main() {
  group('TasteProfileService', () {
    test('builds favorite and history affinities', () {
      final service = TasteProfileService();
      final historySong = _song('1', 'Indie Rock', 'Aurora', 'Indie Rock');
      final history = <ListeningHistoryEntry>[
        ListeningHistoryEntry(
          song: historySong,
          lastPlayed: DateTime.now(),
          playCount: 4,
          position: const Duration(minutes: 3),
          duration: const Duration(minutes: 3),
        ),
      ];

      final profile = service.build(
        history: history,
        favoriteArtists: const <String>['Aurora'],
        favoriteIds: const <String>['favorite-id'],
      );

      expect(profile.favoriteArtists, contains('aurora'));
      expect(profile.favoriteIds, contains('favorite-id'));
      expect(profile.artists, contains('aurora'));
      expect(profile.genres, contains('rock'));
    });

    test('ranks favorite artist and favorite track strongly', () {
      final service = TasteProfileService();
      const profile = TasteProfile(
        genres: <String, double>{'pop': 2},
        artists: <String, double>{'aurora': 1},
        albums: <String, double>{},
        favoriteArtists: <String>{'aurora'},
        favoriteIds: <String>{'fav'},
      );

      final ranked = service.rank(<OnlineSong>[
        _online('other', 'Song', 'Other Artist', 'Album'),
        _online('fav', 'Song', 'Aurora', 'Album'),
      ], profile);

      expect(ranked.first.id, 'fav');
    });

    test('excluded IDs are omitted', () {
      final service = TasteProfileService();
      const profile = TasteProfile(
        genres: <String, double>{},
        artists: <String, double>{},
        albums: <String, double>{},
        favoriteArtists: <String>{},
        favoriteIds: <String>{},
      );

      final ranked = service.rank(
        <OnlineSong>[
          _online('1', 'One', 'Artist', 'Album'),
          _online('2', 'Two', 'Artist', 'Album'),
        ],
        profile,
        excludedIds: const <String>{'1'},
      );

      expect(ranked.map((song) => song.id), contains('2'));
      expect(ranked.map((song) => song.id), isNot(contains('1')));
    });
  });
}
