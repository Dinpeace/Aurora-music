import 'package:flutter_test/flutter_test.dart';
import 'package:aurora_music/data/models/song.dart';
import 'package:aurora_music/data/services/predictive_queue_intent_service.dart';
import 'package:aurora_music/data/services/continuous_session_learning_service.dart';
import 'package:aurora_music/data/services/session_intelligence_service.dart';
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

  test('starts with a balanced direction', () {
    final session = SessionIntelligenceService();
    final predictor = PredictiveQueueIntentService(session: session);
    final learner = ContinuousSessionLearningService(
      session: session,
      predictor: predictor,
    );

    expect(learner.direction, ListeningMode.balanced);
    expect(learner.discoverySignal, 0.0);
    expect(learner.favoritesSignal, 0.0);
  });

  test('learns sustained skip direction incrementally', () {
    final session = SessionIntelligenceService();
    final predictor = PredictiveQueueIntentService(session: session);
    final learner = ContinuousSessionLearningService(
      session: session,
      predictor: predictor,
    );

    for (var i = 0; i < 5; i++) {
      final id = 'skip-$i';
      session.recordPlay(song(id));
      session.recordSkip(id);
      learner.learn();
    }

    expect(learner.discoverySignal, greaterThan(0.45));
    expect(learner.direction, ListeningMode.discovery);
  });

  test('learns sustained favorite direction incrementally', () {
    final session = SessionIntelligenceService();
    final predictor = PredictiveQueueIntentService(session: session);
    final learner = ContinuousSessionLearningService(
      session: session,
      predictor: predictor,
    );

    for (var i = 0; i < 5; i++) {
      session.recordPlay(song('play-$i', artist: 'Aurora'));
      learner.learn();
    }

    expect(learner.favoritesSignal, greaterThan(0.45));
    expect(learner.direction, ListeningMode.favorites);
  });

  test('does not learn again when no new session events arrive', () {
    final session = SessionIntelligenceService();
    final predictor = PredictiveQueueIntentService(session: session);
    final learner = ContinuousSessionLearningService(
      session: session,
      predictor: predictor,
    );

    session.recordPlay(song('one', artist: 'Aurora'));
    learner.learn();
    final first = learner.favoritesSignal;

    learner.learn();

    expect(learner.favoritesSignal, first);
  });

  test('reset clears learning state without clearing session evidence', () {
    final session = SessionIntelligenceService();
    final predictor = PredictiveQueueIntentService(session: session);
    final learner = ContinuousSessionLearningService(
      session: session,
      predictor: predictor,
    );

    for (var i = 0; i < 3; i++) {
      session.recordPlay(song('play-$i', artist: 'Aurora'));
      learner.learn();
    }

    learner.reset();

    expect(learner.direction, ListeningMode.balanced);
    expect(learner.discoverySignal, 0.0);
    expect(learner.favoritesSignal, 0.0);
    expect(session.playedCount, 3);
  });
}
