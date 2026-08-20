import 'package:flutter_test/flutter_test.dart';
import 'package:aurora_music/data/models/song.dart';
import 'package:aurora_music/data/models/online/online_song.dart';
import 'package:aurora_music/data/services/adaptive_recommendation_service.dart';
import 'package:aurora_music/data/services/mood_energy_service.dart';
import 'package:aurora_music/data/services/predictive_queue_intent_service.dart';
import 'package:aurora_music/data/services/predictive_queue_regeneration_service.dart';
import 'package:aurora_music/data/services/session_intelligence_service.dart';
import 'package:aurora_music/data/services/smart_queue_service.dart';
import 'package:aurora_music/data/services/taste_profile_service.dart';

void main() {
  Song song(String id, {String artist = 'Aurora'}) => Song(
        id: id,
        title: id,
        artist: artist,
        album: 'Album',
        artwork: '',
        audioUrl: 'https://example.com/$id.mp3',
        duration: const Duration(minutes: 3),
      );

  OnlineSong onlineSong(String id, {String artist = 'Aurora'}) => OnlineSong(
        id: id,
        title: id,
        artist: artist,
        album: 'Album',
        artwork: '',
        streamUrl: 'https://example.com/$id.mp3',
        duration: const Duration(minutes: 3),
      );

  PredictiveQueueRegenerationService makeService(
    SessionIntelligenceService session,
  ) {
    final predictor = PredictiveQueueIntentService(session: session);
    final queue = SmartQueueService(
      adaptive: AdaptiveRecommendationService(),
      mood: MoodEnergyService(session: session),
      session: session,
    );
    return PredictiveQueueRegenerationService(
      predictor: predictor,
      queue: queue,
    );
  }

  const profile = TasteProfile(
    genres: {},
    artists: {},
    albums: {},
    favoriteArtists: {},
    favoriteIds: {},
  );

  test('does not regenerate before predictive confidence is ready', () {
    final session = SessionIntelligenceService();
    final service = makeService(session);

    final result = service.regenerateTail(
      candidates: [onlineSong('one')],
      currentQueue: [onlineSong('current')],
      profile: profile,
      history: const [],
    );

    expect(result.map((s) => s.id), ['current']);
    expect(service.lastAppliedMode, isNull);
  });

  test('regenerates only after predictive intent becomes confident', () {
    final session = SessionIntelligenceService();
    final service = makeService(session);

    for (var i = 0; i < 3; i++) {
      final id = 'skip-$i';
      session.recordPlay(song(id));
      session.recordSkip(id);
    }
    session.recordPlay(song('four'));

    final result = service.regenerateTail(
      candidates: [onlineSong('fresh-1', artist: 'New'), onlineSong('fresh-2', artist: 'New')],
      currentQueue: [onlineSong('playing')],
      protectedItems: [onlineSong('playing')],
      profile: profile,
      history: const [],
      tailLength: 2,
    );

    expect(service.lastAppliedMode, ListeningMode.discovery);
    expect(result.first.id, 'playing');
    expect(result.length, greaterThanOrEqualTo(1));
  });

  test('does not repeatedly regenerate the same applied mode', () {
    final session = SessionIntelligenceService();
    final predictor = PredictiveQueueIntentService(session: session);
    final queue = SmartQueueService(
      adaptive: AdaptiveRecommendationService(),
      mood: MoodEnergyService(session: session),
      session: session,
    );
    final service = PredictiveQueueRegenerationService(
      predictor: predictor,
      queue: queue,
    );

    for (var i = 0; i < 3; i++) {
      final id = 'skip-$i';
      session.recordPlay(song(id));
      session.recordSkip(id);
    }
    session.recordPlay(song('four'));

    service.regenerateTail(
      candidates: [onlineSong('fresh')],
      currentQueue: [onlineSong('playing')],
      protectedItems: [onlineSong('playing')],
      profile: profile,
      history: const [],
    );

    expect(service.shouldRegenerate, isFalse);
  });

  test('reset allows the current predicted mode to be applied again', () {
    final session = SessionIntelligenceService();
    final service = makeService(session);

    for (var i = 0; i < 3; i++) {
      final id = 'skip-$i';
      session.recordPlay(song(id));
      session.recordSkip(id);
    }
    session.recordPlay(song('four'));

    service.regenerateTail(
      candidates: [onlineSong('fresh')],
      currentQueue: [onlineSong('playing')],
      protectedItems: [onlineSong('playing')],
      profile: profile,
      history: const [],
    );

    expect(service.lastAppliedMode, ListeningMode.discovery);
    service.reset();
    expect(service.lastAppliedMode, isNull);
  });
}
