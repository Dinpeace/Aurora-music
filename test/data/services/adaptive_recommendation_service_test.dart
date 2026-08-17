import 'package:flutter_test/flutter_test.dart';

import 'package:aurora_music/data/models/listening_history_entry.dart';
import 'package:aurora_music/data/models/online/online_song.dart';
import 'package:aurora_music/data/models/song.dart';
import 'package:aurora_music/data/services/adaptive_recommendation_service.dart';
import 'package:aurora_music/data/services/taste_profile_service.dart';

void main() {
  const profile = TasteProfile(
    genres: {'pop': 10},
    artists: {'aurora': 10},
    albums: {'album': 5},
    favoriteArtists: {'aurora'},
    favoriteIds: {},
  );

  final service = AdaptiveRecommendationService();

  OnlineSong onlineSong(String id, String artist, String album) {
    return OnlineSong(
      id: id,
      title: id,
      artist: artist,
      album: album,
      artwork: '',
      streamUrl: 'https://example.com/$id',
      duration: const Duration(minutes: 3),
    );
  }

  Song historySong(OnlineSong song) {
    return Song(
      id: song.id,
      title: song.title,
      artist: song.artist,
      album: song.album,
      artwork: song.artwork.isEmpty ? null : song.artwork,
      audioUrl: song.streamUrl,
      duration: song.duration,
    );
  }

  ListeningHistoryEntry historyEntry({
    required OnlineSong song,
    int plays = 1,
    int skips = 0,
  }) {
    return ListeningHistoryEntry(
      song: historySong(song),
      lastPlayed: DateTime.now(),
      playCount: plays,
      position: const Duration(minutes: 3),
      duration: const Duration(minutes: 3),
      skipCount: skips,
    );
  }

  test('returns ranked recommendations with the requested limit', () {
    final result = service.rank(
      candidates: [
        onlineSong('one', 'Aurora', 'Album'),
        onlineSong('two', 'Other', 'Other Album'),
        onlineSong('three', 'Another', 'Third Album'),
      ],
      profile: profile,
      history: const [],
      limit: 2,
    );

    expect(result, hasLength(2));
  });

  test('skipped tracks receive a strong negative adjustment', () {
    final skipped = onlineSong('skipped', 'Aurora', 'Album');
    final fresh = onlineSong('fresh', 'Other', 'Other Album');

    final result = service.rank(
      candidates: [skipped, fresh],
      profile: profile,
      history: [
        historyEntry(song: skipped, plays: 1, skips: 8),
      ],
      limit: 2,
    );

    expect(result.last.id, 'skipped');
  });

  test('unheard artists receive exploration bonus', () {
    final known = onlineSong('known', 'Aurora', 'Album');
    final newArtist = onlineSong('new', 'New Artist', 'New Album');

    final result = service.rank(
      candidates: [known, newArtist],
      profile: profile,
      history: const [],
      limit: 2,
    );

    expect(result, hasLength(2));
    expect(result.map((item) => item.id).toSet(), {'known', 'new'});
  });

  test('excluded IDs are never returned', () {
    final result = service.rank(
      candidates: [
        onlineSong('one', 'Aurora', 'Album'),
        onlineSong('two', 'Other', 'Other'),
      ],
      profile: profile,
      history: const [],
      excludedIds: {'one'},
      limit: 5,
    );

    expect(result.map((item) => item.id), isNot(contains('one')));
  });
}
