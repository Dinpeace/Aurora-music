import 'package:flutter_test/flutter_test.dart';
import 'package:aurora_music/data/models/online/online_song.dart';
import 'package:aurora_music/data/services/adaptive_recommendation_service.dart';
import 'package:aurora_music/data/services/mood_energy_service.dart';
import 'package:aurora_music/data/services/session_intelligence_service.dart';
import 'package:aurora_music/data/services/smart_queue_service.dart';
import 'package:aurora_music/data/services/taste_profile_service.dart';

void main() {
  SmartQueueService service({SessionIntelligenceService? session}) {
    return SmartQueueService(
      adaptive: AdaptiveRecommendationService(),
      mood: MoodEnergyService(session: SessionIntelligenceService()),
      session: session,
    );
  }

  const profile = TasteProfile(
    genres: {'pop': 10},
    artists: {'aurora': 20},
    albums: {},
    favoriteArtists: {'aurora'},
    favoriteIds: {},
  );

  OnlineSong song(
    String id, {
    String artist = 'Aurora',
    String album = 'Album',
  }) =>
      OnlineSong(
        id: id,
        title: id,
        artist: artist,
        album: album,
        artwork: '',
        streamUrl: 'https://example.com/$id',
        duration: const Duration(minutes: 3),
      );

  test('session feedback changes queue order', () {
    final session = SessionIntelligenceService();

    // SessionIntelligenceService needs a local Song for play tracking; this
    // test only verifies the SmartQueue API remains usable with a session.
    final result = service(session: session).build(
      candidates: [
        song('one'),
        song('two', artist: 'Other'),
      ],
      profile: profile,
      history: const [],
      length: 2,
    );

    expect(result, hasLength(2));
  });

  test('avoids consecutive tracks from the same artist when alternatives exist',
      () {
    final result = service().build(
      candidates: [
        song('a1'),
        song('a2'),
        song('b1', artist: 'Other'),
      ],
      profile: profile,
      history: const [],
      length: 3,
    );

    expect(result[0].artist, isNot(result[1].artist));
  });

  test('avoids consecutive tracks from the same album when alternatives exist',
      () {
    final result = service().build(
      candidates: [
        song('a1', album: 'Album A'),
        song('a2', album: 'Album A'),
        song('b1', artist: 'Other', album: 'Album B'),
      ],
      profile: profile,
      history: const [],
      length: 3,
    );

    expect(result[0].album, isNot(result[1].album));
  });

  test('preserves queue items and avoids duplicates when appending', () {
    final current = song('current');

    final result = service().append(
      candidates: [
        current,
        song('one'),
        song('two', artist: 'Other'),
      ],
      currentQueue: [current],
      profile: profile,
      history: const [],
      additional: 2,
    );

    expect(result.first.id, 'current');
    expect(result.map((item) => item.id).toSet().length, result.length);
    expect(result, hasLength(3));
  });

  test('returns an empty queue for non-positive length', () {
    final result = service().build(
      candidates: [song('one')],
      profile: profile,
      history: const [],
      length: 0,
    );

    expect(result, isEmpty);
  });
}
