import 'package:flutter_test/flutter_test.dart';

import 'package:aurora_music/data/models/online/online_song.dart';
import 'package:aurora_music/data/services/mood_energy_service.dart';
import 'package:aurora_music/data/services/recommendation_engine.dart';
import 'package:aurora_music/data/services/smart_queue_service.dart';
import 'package:aurora_music/data/services/session_intelligence_service.dart';
import 'package:aurora_music/data/services/taste_profile_service.dart';

void main() {
  group('SmartQueueService', () {
    SmartQueueService createService() {
      final session = SessionIntelligenceService();
      final mood = MoodEnergyService(session: session);
      final taste = TasteProfileService();
      final recommendations = RecommendationEngine(
        taste: taste,
        mood: mood,
        session: session,
      );

      return SmartQueueService(
        recommendations: recommendations,
        mood: mood,
      );
    }

    const profile = TasteProfile(
      genres: {'pop': 10},
      artists: {'aurora': 20},
      albums: {},
      favoriteArtists: {'aurora'},
      favoriteIds: {},
    );

    test('does not duplicate current queue items', () {
      final service = createService();

      final current = _song('current', 'Current', 'Aurora', 'Album');
      final candidates = [
        current,
        _song('one', 'One', 'Aurora', 'Album'),
        _song('two', 'Two', 'Other', 'Album'),
      ];

      final result = service.build(
        candidates: candidates,
        currentQueue: [current],
        profile: profile,
        mood: MoodProfile.happy,
        length: 2,
      );

      expect(result.map((song) => song.id), isNot(contains('current')));
      expect(result.map((song) => song.id).toSet(), hasLength(result.length));
    });

    test('respects requested queue length when enough candidates exist', () {
      final service = createService();

      final candidates = List.generate(
        8,
        (index) => _song(
          'song-$index',
          'Song $index',
          index.isEven ? 'Aurora' : 'Other Artist',
          'Album',
        ),
      );

      final result = service.build(
        candidates: candidates,
        profile: profile,
        mood: MoodProfile.chill,
        length: 5,
      );

      expect(result, hasLength(5));
    });

    test('returns empty queue for non-positive length', () {
      final service = createService();

      expect(
        service.build(
          candidates: [_song('one', 'One', 'Artist', 'Album')],
          profile: profile,
          length: 0,
        ),
        isEmpty,
      );
    });

    test('append preserves existing queue', () {
      final service = createService();
      final current = _song('current', 'Current', 'Artist', 'Album');

      final result = service.append(
        candidates: [
          current,
          _song('one', 'One', 'Artist', 'Album'),
          _song('two', 'Two', 'Other', 'Album'),
        ],
        currentQueue: [current],
        profile: profile,
        additional: 2,
      );

      expect(result.first.id, 'current');
      expect(result.length, greaterThanOrEqualTo(1));
    });
  });
}

OnlineSong _song(
  String id,
  String title,
  String artist,
  String album,
) {
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
