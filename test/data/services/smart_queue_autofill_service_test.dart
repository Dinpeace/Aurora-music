import 'package:flutter_test/flutter_test.dart';

import 'package:aurora_music/data/models/online/online_song.dart';
import 'package:aurora_music/data/services/mood_energy_service.dart';
import 'package:aurora_music/data/services/recommendation_engine.dart';
import 'package:aurora_music/data/services/session_intelligence_service.dart';
import 'package:aurora_music/data/services/smart_queue_autofill_service.dart';
import 'package:aurora_music/data/services/smart_queue_service.dart';
import 'package:aurora_music/data/services/taste_profile_service.dart';

void main() {
  SmartQueueAutofillService createService() {
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

    return SmartQueueAutofillService(
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

  final candidates = List<OnlineSong>.generate(
    12,
    (index) => _song(
      'candidate-$index',
      'Candidate $index',
      index.isEven ? 'Aurora' : 'Other Artist',
      'Album',
    ),
  );

  test('autofills only near the end of the queue', () {
    final service = createService();
    final queue = [
      _song('q1', 'Queue 1', 'Artist', 'Album'),
      _song('q2', 'Queue 2', 'Artist', 'Album'),
      _song('q3', 'Queue 3', 'Artist', 'Album'),
      _song('q4', 'Queue 4', 'Artist', 'Album'),
    ];

    final unchanged = service.autofill(
      candidates: candidates,
      currentQueue: queue,
      currentIndex: 0,
      profile: profile,
    );
    expect(unchanged, hasLength(4));

    final expanded = service.autofill(
      candidates: candidates,
      currentQueue: queue,
      currentIndex: 2,
      profile: profile,
      additional: 3,
    );
    expect(expanded.length, greaterThan(4));
  });

  test('fillToMinimum adds only what is needed up to batch size', () {
    final service = createService();

    final result = service.fillToMinimum(
      candidates: candidates,
      currentQueue: [
        _song('q1', 'Queue 1', 'Artist', 'Album'),
        _song('q2', 'Queue 2', 'Artist', 'Album'),
      ],
      profile: profile,
      minimumLength: 6,
      batchSize: 5,
    );

    expect(result.length, lessThanOrEqualTo(7));
    expect(result.length, greaterThan(2));
  });

  test('negative or empty positions never trigger autofill', () {
    final service = createService();

    expect(
      service.shouldAutofill(
        currentIndex: -1,
        queueLength: 5,
      ),
      isFalse,
    );
    expect(
      service.shouldAutofill(
        currentIndex: 0,
        queueLength: 0,
      ),
      isFalse,
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
