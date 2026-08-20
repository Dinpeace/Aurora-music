import 'package:flutter_test/flutter_test.dart';
import 'package:aurora_music/data/models/song.dart';
import 'package:aurora_music/data/services/continuous_session_learning_service.dart';
import 'package:aurora_music/data/services/predictive_queue_intent_service.dart';
import 'package:aurora_music/data/services/session_intelligence_service.dart';
import 'package:aurora_music/data/services/session_pattern_recognition_service.dart';

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

  SessionPatternRecognitionService make(
    SessionIntelligenceService session,
  ) {
    final predictor = PredictiveQueueIntentService(session: session);
    final learner = ContinuousSessionLearningService(
      session: session,
      predictor: predictor,
    );
    return SessionPatternRecognitionService(
      session: session,
      learner: learner,
    );
  }

  test('starts without a recognized pattern', () {
    final session = SessionIntelligenceService();
    final recognizer = make(session);

    expect(recognizer.observe(), isEmpty);
    expect(recognizer.patterns, isEmpty);
  });

  test('recognizes repeated skip discovery', () {
    final session = SessionIntelligenceService();
    final recognizer = make(session);

    for (var i = 0; i < 5; i++) {
      final id = 'skip-$i';
      session.recordPlay(song(id));
      session.recordSkip(id);
      recognizer.observe();
    }

    expect(recognizer.hasPattern('repeated_skip_discovery'), isTrue);
  });

  test('recognizes artist affinity', () {
    final session = SessionIntelligenceService();
    final recognizer = make(session);

    for (var i = 0; i < 5; i++) {
      session.recordPlay(song('fav-$i', artist: 'Aurora'));
      recognizer.observe();
    }

    expect(recognizer.hasPattern('artist_affinity'), isTrue);
  });

  test('recognizes completion-heavy style when there are no skips', () {
    final session = SessionIntelligenceService();
    final recognizer = make(session);

    for (var i = 0; i < 4; i++) {
      session.recordPlay(song('complete-$i'));
      session.recordCompletion('complete-$i');
      recognizer.observe();
    }

    expect(recognizer.hasPattern('completion_heavy'), isTrue);
  });

  test('reset clears only pattern memory', () {
    final session = SessionIntelligenceService();
    final recognizer = make(session);

    session.recordPlay(song('one'));
    recognizer.observe();
    recognizer.reset();

    expect(recognizer.patterns, isEmpty);
    expect(session.playedCount, 1);
  });
}
