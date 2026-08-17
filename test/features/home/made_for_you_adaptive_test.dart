import 'package:flutter_test/flutter_test.dart';

import 'package:aurora_music/data/models/listening_history_entry.dart';
import 'package:aurora_music/data/models/online/online_song.dart';
import 'package:aurora_music/data/models/song.dart';
import 'package:aurora_music/data/services/adaptive_recommendation_service.dart';
import 'package:aurora_music/data/services/taste_profile_service.dart';

void main() {
  test('adaptive ranking favors a repeated song over an unheard song', () {
    final adaptive = AdaptiveRecommendationService();

    final repeated = _online('repeated', 'Aurora', 'Album');
    final unheard = _online('unheard', 'Other Artist', 'Other Album');

    final profile = const TasteProfile(
      genres: {},
      artists: {'aurora': 10},
      albums: {'album': 5},
      favoriteArtists: {'aurora'},
      favoriteIds: {},
    );

    final history = [
      ListeningHistoryEntry(
        song: _local(repeated),
        lastPlayed: DateTime.now(),
        playCount: 6,
        position: repeated.duration,
        duration: repeated.duration,
        skipCount: 0,
      ),
    ];

    final result = adaptive.rank(
      candidates: [unheard, repeated],
      profile: profile,
      history: history,
      limit: 2,
    );

    expect(result.first.id, 'repeated');
  });

  test('repeatedly skipped tracks are pushed down', () {
    final adaptive = AdaptiveRecommendationService();

    final skipped = _online('skipped', 'Aurora', 'Album');
    final fresh = _online('fresh', 'Other Artist', 'Other Album');

    final profile = const TasteProfile(
      genres: {},
      artists: {'aurora': 10},
      albums: {'album': 5},
      favoriteArtists: {'aurora'},
      favoriteIds: {},
    );

    final history = [
      ListeningHistoryEntry(
        song: _local(skipped),
        lastPlayed: DateTime.now(),
        playCount: 1,
        position: const Duration(seconds: 10),
        duration: skipped.duration,
        skipCount: 8,
      ),
    ];

    final result = adaptive.rank(
      candidates: [skipped, fresh],
      profile: profile,
      history: history,
      limit: 2,
    );

    expect(result.last.id, 'skipped');
  });
}

OnlineSong _online(String id, String artist, String album) => OnlineSong(
      id: id,
      title: id,
      artist: artist,
      album: album,
      artwork: '',
      streamUrl: 'https://example.com/$id',
      duration: const Duration(minutes: 3),
    );

Song _local(OnlineSong song) => Song(
      id: song.id,
      title: song.title,
      artist: song.artist,
      album: song.album,
      audioUrl: song.streamUrl,
      duration: song.duration,
    );
