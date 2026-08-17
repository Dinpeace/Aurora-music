import 'package:flutter_test/flutter_test.dart';
import 'package:aurora_music/data/models/online/online_song.dart';
import 'package:aurora_music/data/services/adaptive_recommendation_service.dart';
import 'package:aurora_music/data/services/mood_energy_service.dart';
import 'package:aurora_music/data/services/session_intelligence_service.dart';
import 'package:aurora_music/data/services/smart_queue_autofill_service.dart';
import 'package:aurora_music/data/services/smart_queue_service.dart';
import 'package:aurora_music/data/services/taste_profile_service.dart';

void main() {
  SmartQueueAutofillService createService() {
    final mood = MoodEnergyService(session: SessionIntelligenceService());
    return SmartQueueAutofillService(
      smartQueue: SmartQueueService(
        adaptive: AdaptiveRecommendationService(),
        mood: mood,
      ),
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

  OnlineSong song(String id) => OnlineSong(
        id: id,
        title: id,
        artist: 'Aurora',
        album: 'Album',
        artwork: '',
        streamUrl: 'https://example.com/$id',
        duration: const Duration(minutes: 3),
      );

  test('autofills near the end', () {
    final service = createService();
    final queue = [song('q1'), song('q2'), song('q3'), song('q4')];

    final result = service.autofill(
      candidates: List.generate(8, (i) => song('c$i')),
      currentQueue: queue,
      currentIndex: 2,
      profile: profile,
      history: const [],
      additional: 2,
    );

    expect(result.length, greaterThan(4));
  });

  test('does not autofill away from the end', () {
    expect(
      createService().shouldAutofill(currentIndex: 0, queueLength: 6),
      isFalse,
    );
  });
}
