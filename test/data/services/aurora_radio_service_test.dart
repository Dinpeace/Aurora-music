import 'package:flutter_test/flutter_test.dart';
import 'package:aurora_music/data/models/online/online_song.dart';
import 'package:aurora_music/data/services/adaptive_recommendation_service.dart';
import 'package:aurora_music/data/services/aurora_radio_service.dart';
import 'package:aurora_music/data/services/mood_energy_service.dart';
import 'package:aurora_music/data/services/session_intelligence_service.dart';
import 'package:aurora_music/data/services/smart_queue_service.dart';
import 'package:aurora_music/data/services/taste_profile_service.dart';

void main() {
  AuroraRadioService createService() {
    final mood = MoodEnergyService(session: SessionIntelligenceService());
    final adaptive = AdaptiveRecommendationService();
    return AuroraRadioService(
      adaptive: adaptive,
      smartQueue: SmartQueueService(adaptive: adaptive, mood: mood),
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
        _song('same', 'Same', 'Aurora', 'Other'),
        _song('other', 'Other', 'Other', 'Other'),
      ],
      profile: profile,
      history: const [],
      mode: AuroraRadioMode.song,
      seed: seed,
      length: 3,
    );

    expect(result.first.id, 'seed');
  });

  test('personalized radio respects length', () {
    final result = createService().build(
      candidates: List.generate(
        8,
        (i) => _song(
          's$i',
          'Song $i',
          i.isEven ? 'Aurora' : 'Other',
          'Album',
        ),
      ),
      profile: profile,
      history: const [],
      length: 5,
    );

    expect(result, hasLength(5));
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
