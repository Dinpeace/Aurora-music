import 'package:flutter_test/flutter_test.dart';

import 'package:aurora_music/data/models/online/online_song.dart';
import 'package:aurora_music/data/models/song.dart';
import 'package:aurora_music/data/services/mood_energy_service.dart';
import 'package:aurora_music/data/services/recommendation_engine.dart';
import 'package:aurora_music/data/services/session_intelligence_service.dart';
import 'package:aurora_music/data/services/taste_profile_service.dart';

void main() {
  group('RecommendationEngine', () {
    test('returns candidates in ranked order and respects limit', () {
      final session = SessionIntelligenceService();
      final mood = MoodEnergyService(session: session);
      final taste = TasteProfileService();
      final engine = RecommendationEngine(
        taste: taste,
        mood: mood,
        session: session,
      );

      final profile = const TasteProfile(
        genres: {'pop': 10},
        artists: {'aurora': 20},
        albums: {},
        favoriteArtists: {'aurora'},
        favoriteIds: {'fav'},
      );

      final candidates = <OnlineSong>[
        _song('other', 'Other Song', 'Other Artist', 'Album'),
        _song('fav', 'Favorite Song', 'Unknown Artist', 'Album'),
        _song('aurora-2', 'Aurora Song', 'Aurora', 'Album'),
      ];

      final result = engine.rank(
        candidates: candidates,
        profile: profile,
        mood: MoodProfile.happy,
        limit: 2,
      );

      expect(result, hasLength(2));
      expect(result.first.id, anyOf('fav', 'aurora-2'));
    });

    test('excludes skipped session tracks', () {
      final session = SessionIntelligenceService();
      final mood = MoodEnergyService(session: session);
      final taste = TasteProfileService();
      final engine = RecommendationEngine(
        taste: taste,
        mood: mood,
        session: session,
      );

      final skipped = _song('skip', 'Skipped', 'Artist', 'Album');
      final liked = _song('keep', 'Keep', 'Artist', 'Album');

      session.recordPlay(_toLocalSong(skipped));
      session.recordSkip(skipped.id);

      final profile = const TasteProfile(
        genres: {},
        artists: {},
        albums: {},
        favoriteArtists: {},
        favoriteIds: {},
      );

      final result = engine.rank(
        candidates: [skipped, liked],
        profile: profile,
        limit: 10,
      );

      expect(result.map((song) => song.id), isNot(contains('skip')));
      expect(result.map((song) => song.id), contains('keep'));
    });
  });
}

OnlineSong _song(String id, String title, String artist, String album) {
  return OnlineSong(
    id: id,
    title: title,
    artist: artist,
    album: album,
    artwork: '',
    streamUrl: 'https://example.com/$id',
    duration: Duration.zero,
  );
}

Song _toLocalSong(OnlineSong song) {
  return Song(
    id: song.id,
    title: song.title,
    artist: song.artist,
    album: song.album,
    artwork: null,
    audioUrl: song.streamUrl,
    duration: song.duration,
  );
}
