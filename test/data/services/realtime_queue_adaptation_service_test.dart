import 'package:flutter_test/flutter_test.dart';
import 'package:aurora_music/data/models/online/online_song.dart';
import 'package:aurora_music/data/models/song.dart';
import 'package:aurora_music/data/services/adaptive_recommendation_service.dart';
import 'package:aurora_music/data/services/mood_energy_service.dart';
import 'package:aurora_music/data/services/predictive_queue_intent_service.dart';
import 'package:aurora_music/data/services/realtime_queue_adaptation_service.dart';
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

  RealtimeQueueAdaptationService makeService(
    SessionIntelligenceService session,
  ) {
    final predictor = PredictiveQueueIntentService(session: session);
    final queue = SmartQueueService(
      adaptive: AdaptiveRecommendationService(),
      mood: MoodEnergyService(session: session),
      session: session,
    );
    return RealtimeQueueAdaptationService(
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

  test('does not adapt before confidence is ready', () {
    final session = SessionIntelligenceService();
    final service = makeService(session);

    final current = [onlineSong('playing'), onlineSong('old-tail')];
    final result = service.adaptTail(
      candidates: [onlineSong('fresh')],
      currentQueue: current,
      protectedItems: [onlineSong('playing')],
      profile: profile,
      history: const [],
    );

    expect(result.map((s) => s.id), ['playing', 'old-tail']);
    expect(service.generation, 0);
  });

  test('adapts only the unprotected tail when intent changes', () {
    final session = SessionIntelligenceService();
    final service = makeService(session);

    for (var i = 0; i < 3; i++) {
      final id = 'skip-$i';
      session.recordPlay(song(id));
      session.recordSkip(id);
    }
    session.recordPlay(song('four'));

    final result = service.adaptTail(
      candidates: [
        onlineSong('fresh-1', artist: 'New'),
        onlineSong('fresh-2', artist: 'New'),
      ],
      currentQueue: [onlineSong('playing'), onlineSong('old-tail')],
      protectedItems: [onlineSong('playing')],
      profile: profile,
      history: const [],
      tailLength: 2,
    );

    expect(result.first.id, 'playing');
    expect(service.appliedMode, ListeningMode.discovery);
    expect(service.generation, 1);
  });

  test('does not regenerate repeatedly for the same predicted mode', () {
    final session = SessionIntelligenceService();
    final service = makeService(session);

    for (var i = 0; i < 3; i++) {
      final id = 'skip-$i';
      session.recordPlay(song(id));
      session.recordSkip(id);
    }
    session.recordPlay(song('four'));

    final args = <String, Object>{
      'unused': '',
    };
    expect(args['unused'], '');

    service.adaptTail(
      candidates: [onlineSong('fresh')],
      currentQueue: [onlineSong('playing')],
      protectedItems: [onlineSong('playing')],
      profile: profile,
      history: const [],
    );

    expect(service.shouldAdapt(), isFalse);
    expect(service.generation, 1);
  });

  test('reset allows the same intent to be applied again', () {
    final session = SessionIntelligenceService();
    final service = makeService(session);

    for (var i = 0; i < 3; i++) {
      final id = 'skip-$i';
      session.recordPlay(song(id));
      session.recordSkip(id);
    }
    session.recordPlay(song('four'));

    final queue = [onlineSong('playing')];

    service.adaptTail(
      candidates: [onlineSong('fresh')],
      currentQueue: queue,
      protectedItems: queue,
      profile: profile,
      history: const [],
    );

    service.reset();

    expect(service.appliedMode, isNull);
    expect(service.generation, 0);
    expect(service.shouldAdapt(), isTrue);
  });
}
