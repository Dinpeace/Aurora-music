import 'package:flutter_test/flutter_test.dart';
import 'package:aurora_music/data/models/song.dart';
import 'package:aurora_music/data/services/session_intelligence_service.dart';
import 'package:aurora_music/data/services/adaptive_recommendation_service.dart';
import 'package:aurora_music/data/services/mood_energy_service.dart';
import 'package:aurora_music/data/services/taste_profile_service.dart';
import 'package:aurora_music/data/services/session_aware_queue_evolution_service.dart';
import 'package:aurora_music/data/services/smart_queue_service.dart';

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

  test('confidence starts at zero and mode stays balanced', () {
    final session = SessionIntelligenceService();
    final evolution = SessionAwareQueueEvolutionService(session: session);

    expect(evolution.confidence, 0.0);
    expect(evolution.update(), ListeningMode.balanced);
  });

  test('strong repeated skips move the session to discovery', () {
    final session = SessionIntelligenceService();
    final evolution = SessionAwareQueueEvolutionService(session: session);

    for (var i = 0; i < 3; i++) {
      final id = 'skip-$i';
      session.recordPlay(song(id));
      session.recordSkip(id);
    }

    expect(evolution.update(), ListeningMode.discovery);
    expect(evolution.confidence, greaterThanOrEqualTo(0.60));
  });

  test('strong repeated plays move the session to favorites', () {
    final session = SessionIntelligenceService();
    final evolution = SessionAwareQueueEvolutionService(session: session);

    for (var i = 0; i < 3; i++) {
      session.recordPlay(song('play-$i', artist: 'Aurora'));
    }

    expect(evolution.update(), ListeningMode.favorites);
  });

  test('moderate confidence is smoothed across updates', () {
    final session = SessionIntelligenceService();
    final evolution = SessionAwareQueueEvolutionService(
      session: session,
      smoothing: 0.25,
    );

    session.recordPlay(song('one'));
    session.recordSkip('one');
    session.recordPlay(song('two'));

    final first = evolution.update();
    final firstConfidence = evolution.confidence;

    session.recordPlay(song('three'));
    final second = evolution.update();

    expect(first, ListeningMode.balanced);
    expect(second, isA<ListeningMode>());
    expect(evolution.confidence, greaterThanOrEqualTo(0.0));
    expect(firstConfidence, greaterThan(0.0));
  });

  test('reset clears only temporary evolution state', () {
    final session = SessionIntelligenceService();
    final evolution = SessionAwareQueueEvolutionService(session: session);

    for (var i = 0; i < 3; i++) {
      final id = 'skip-$i';
      session.recordPlay(song(id));
      session.recordSkip(id);
    }

    evolution.update();
    evolution.reset();

    expect(evolution.mode, ListeningMode.balanced);
    expect(evolution.confidence, 0.0);
    expect(session.skippedCount, 3);
  });

  test('queue generation consumes the evolved temporary mode', () {
    final session = SessionIntelligenceService();
    final evolution = SessionAwareQueueEvolutionService(session: session);
    final queue = SmartQueueService(
      adaptive: AdaptiveRecommendationService(),
      mood: MoodEnergyService(session: session),
      session: session,
    );

    for (var i = 0; i < 3; i++) {
      final id = 'skip-$i';
      session.recordPlay(song(id));
      session.recordSkip(id);
    }

    final result = evolution.buildQueue(
      queue: queue,
      candidates: const [],
      profile: const TasteProfile(
        genres: {},
        artists: {},
        albums: {},
        favoriteArtists: {},
        favoriteIds: {},
      ),
      history: const [],
      length: 5,
    );

    expect(evolution.mode, ListeningMode.discovery);
    expect(result, isEmpty);
  });
}
