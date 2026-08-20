import 'package:flutter_test/flutter_test.dart';
import 'package:aurora_music/data/models/song.dart';
import 'package:aurora_music/data/services/continuous_session_learning_service.dart';
import 'package:aurora_music/data/services/predictive_queue_intent_service.dart';
import 'package:aurora_music/data/services/queue_intelligence_coordinator.dart';
import 'package:aurora_music/data/services/session_intelligence_service.dart';
import 'package:aurora_music/data/services/session_pattern_recognition_service.dart';
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

  QueueIntelligenceCoordinator makeCoordinator(
    SessionIntelligenceService session,
  ) {
    final predictor = PredictiveQueueIntentService(session: session);
    final learner = ContinuousSessionLearningService(
      session: session,
      predictor: predictor,
    );
    final patterns = SessionPatternRecognitionService(
      session: session,
      learner: learner,
    );

    return QueueIntelligenceCoordinator(
      session: session,
      predictor: predictor,
      learner: learner,
      patterns: patterns,
    );
  }

  test('starts with a balanced low-confidence decision', () {
    final session = SessionIntelligenceService();
    final coordinator = makeCoordinator(session);

    final decision = coordinator.evaluate();

    expect(decision.mode, ListeningMode.balanced);
    expect(decision.confidence, 0.0);
    expect(decision.patterns, isEmpty);
    expect(decision.playedCount, 0);
    expect(decision.skippedCount, 0);
    expect(decision.isConfident, isFalse);
  });

  test('fuses repeated skips into a discovery decision', () {
    final session = SessionIntelligenceService();
    final coordinator = makeCoordinator(session);

    for (var i = 0; i < 5; i++) {
      final id = 'skip-$i';
      session.recordPlay(song(id));
      session.recordSkip(id);
      coordinator.evaluate();
    }

    final decision = coordinator.evaluate();

    expect(decision.mode, ListeningMode.discovery);
    expect(decision.discoverySignal, greaterThanOrEqualTo(0.55));
    expect(
      decision.patterns,
      contains('repeated_skip_discovery'),
    );
    expect(decision.isConfident, isTrue);
  });

  test('fuses concentrated successful listening into favorites', () {
    final session = SessionIntelligenceService();
    final coordinator = makeCoordinator(session);

    for (var i = 0; i < 5; i++) {
      session.recordPlay(song('favorite-$i', artist: 'Aurora'));
      coordinator.evaluate();
    }

    final decision = coordinator.evaluate();

    expect(decision.mode, ListeningMode.favorites);
    expect(decision.familiaritySignal, greaterThanOrEqualTo(0.45));
    expect(decision.patterns, contains('artist_affinity'));
  });

  test('discovery conflict wins over familiarity when rejection is strong', () {
    final session = SessionIntelligenceService();
    final coordinator = makeCoordinator(session);

    for (var i = 0; i < 5; i++) {
      final id = 'skip-$i';
      session.recordPlay(song(id, artist: 'Aurora'));
      session.recordSkip(id);
      coordinator.evaluate();
    }

    final decision = coordinator.evaluate();

    expect(decision.mode, ListeningMode.discovery);
    expect(
      decision.discoverySignal,
      greaterThan(decision.familiaritySignal),
    );
  });

  test('reset clears only coordinator-owned temporary intelligence', () {
    final session = SessionIntelligenceService();
    final coordinator = makeCoordinator(session);

    session.recordPlay(song('one', artist: 'Aurora'));
    coordinator.evaluate();

    coordinator.reset();

    final decision = coordinator.lastDecision;

    expect(decision.mode, ListeningMode.balanced);
    expect(decision.confidence, 0.0);
    expect(decision.patterns, isEmpty);
    expect(session.playedCount, 1);
  });

  test('decision remains immutable after later session changes', () {
    final session = SessionIntelligenceService();
    final coordinator = makeCoordinator(session);

    session.recordPlay(song('one'));
    final first = coordinator.evaluate();

    session.recordPlay(song('two'));
    final second = coordinator.evaluate();

    expect(first.playedCount, 1);
    expect(second.playedCount, 2);
  });
}
