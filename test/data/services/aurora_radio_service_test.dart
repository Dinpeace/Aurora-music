import 'package:flutter_test/flutter_test.dart';

import 'package:aurora_music/data/models/online/online_song.dart';
import 'package:aurora_music/data/services/aurora_radio_service.dart';
import 'package:aurora_music/data/services/mood_energy_service.dart';
import 'package:aurora_music/data/services/recommendation_engine.dart';
import 'package:aurora_music/data/services/session_intelligence_service.dart';
import 'package:aurora_music/data/services/smart_queue_service.dart';
import 'package:aurora_music/data/services/taste_profile_service.dart';

void main() {
  AuroraRadioService createService() {
    final session = SessionIntelligenceService();
    final mood = MoodEnergyService(session: session);
    final taste = TasteProfileService();
    final recommendations = RecommendationEngine(
      taste: taste,
      mood: mood,
      session: session,
    );
    final queue = SmartQueueService(
      recommendations: recommendations,
      mood: mood,
    );

    return AuroraRadioService(
      recommendations: recommendations,
      smartQueue: queue,
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

  test('song radio starts with the seed', () {
    final service = createService();
    final seed = _song('seed', 'Seed', 'Aurora', 'Album');

    final result = service.build(
      candidates: [
        seed,
        _song('same-artist', 'Same Artist', 'Aurora', 'Other Album'),
        _song('other', 'Other', 'Other Artist', 'Other Album'),
      ],
      profile: profile,
      mode: AuroraRadioMode.song,
      seed: seed,
      length: 3,
    );

    expect(result, isNotEmpty);
    expect(result.first.id, 'seed');
  });

  test('artist radio prioritizes the seed artist', () {
    final service = createService();
    final seed = _song('seed', 'Seed', 'Aurora', 'Album');

    final result = service.build(
      candidates: [
        seed,
        _song('aurora-2', 'Aurora Two', 'Aurora', 'Other'),
        _song('other', 'Other', 'Other Artist', 'Album'),
      ],
      profile: profile,
      mode: AuroraRadioMode.artist,
      seed: seed,
      length: 2,
    );

    expect(result, isNotEmpty);
    expect(result.first.artist.toLowerCase(), 'aurora');
  });

  test('personalized radio respects requested length', () {
    final service = createService();

    final result = service.build(
      candidates: List.generate(
        8,
        (index) => _song(
          'song-$index',
          'Song $index',
          index.isEven ? 'Aurora' : 'Other',
          'Album',
        ),
      ),
      profile: profile,
      length: 5,
    );

    expect(result, hasLength(5));
  });

  test('non-positive length returns empty', () {
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
