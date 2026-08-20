import 'package:flutter_test/flutter_test.dart';
import 'package:aurora_music/data/models/online/online_song.dart';
import 'package:aurora_music/data/models/song.dart';
import 'package:aurora_music/data/services/continuous_session_learning_service.dart';
import 'package:aurora_music/data/services/pattern_aware_queue_strategy_service.dart';
import 'package:aurora_music/data/services/predictive_queue_intent_service.dart';
import 'package:aurora_music/data/services/session_intelligence_service.dart';
import 'package:aurora_music/data/services/session_pattern_recognition_service.dart';
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

  SessionPatternRecognitionService recognizerFor(
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

  test('empty patterns preserve the upstream order', () {
    final session = SessionIntelligenceService();
    final recognizer = recognizerFor(session);
    final strategy = PatternAwareQueueStrategyService(
      recognizer: recognizer,
    );

    final songs = [
      onlineSong('one'),
      onlineSong('two'),
      onlineSong('three'),
    ];

    expect(
      strategy.rank(ranked: songs, limit: 2).map((s) => s.id),
      ['one', 'two'],
    );
  });

  test('discovery pattern changes ranking without changing candidates', () {
    final session = SessionIntelligenceService();
    final recognizer = recognizerFor(session);

    for (var i = 0; i < 5; i++) {
      final id = 'skip-$i';
      session.recordPlay(song(id));
      session.recordSkip(id);
      recognizer.observe();
    }

    final strategy = PatternAwareQueueStrategyService(
      recognizer: recognizer,
    );

    final input = [
      onlineSong('plain'),
      onlineSong('live-track'),
      onlineSong('remix-track'),
    ];

    final output = strategy.rank(ranked: input, limit: 3);

    expect(strategy.patterns, contains('repeated_skip_discovery'));
    expect(output.length, 3);
    expect(output.map((s) => s.id).toSet(), input.map((s) => s.id).toSet());
    expect(output.first.id, 'live-track');
  });

  test('affinity pattern is recognized and remains session scoped', () {
    final session = SessionIntelligenceService();
    final recognizer = recognizerFor(session);

    for (var i = 0; i < 5; i++) {
      session.recordPlay(song('fav-$i', artist: 'Aurora'));
      recognizer.observe();
    }

    final strategy = PatternAwareQueueStrategyService(
      recognizer: recognizer,
    );

    expect(strategy.patterns, contains('artist_affinity'));

    recognizer.reset();

    expect(strategy.patterns, isEmpty);
  });

  test('completion-heavy pattern is recognized', () {
    final session = SessionIntelligenceService();
    final recognizer = recognizerFor(session);

    for (var i = 0; i < 4; i++) {
      final id = 'complete-$i';
      session.recordPlay(song(id));
      session.recordCompletion(id);
      recognizer.observe();
    }

    expect(recognizer.hasPattern('completion_heavy'), isTrue);
  });

  test('pattern strategy never mutates persistent profile', () {
    final session = SessionIntelligenceService();
    final recognizer = recognizerFor(session);
    final strategy = PatternAwareQueueStrategyService(
      recognizer: recognizer,
    );

    const profile = TasteProfile(
      genres: {},
      artists: {},
      albums: {},
      favoriteArtists: {},
      favoriteIds: {},
    );

    final before = profile.favoriteArtists;

    strategy.rank(
      ranked: [onlineSong('one')],
      limit: 1,
    );

    expect(profile.favoriteArtists, same(before));
  });
}
