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

  OnlineSong song(String id, {
    String artist = 'Aurora',
    String album = 'Album',
  }) => OnlineSong(
        id: id,
        title: id,
        artist: artist,
        album: album,
        artwork: '',
        streamUrl: 'https://example.com/$id',
        duration: const Duration(minutes: 3),
      );

  test('regeneration never re-adds current queue tracks', () {
    final current = song('current');

    final result = service().regenerate(
      candidates: [
        current,
        song('one', artist: 'Other'),
        song('two', artist: 'Third'),
      ],
      currentQueue: [current],
      profile: profile,
      history: const [],
      length: 2,
    );

    expect(result.first.id, 'current');
    expect(result.map((item) => item.id), containsAll(<String>['one', 'two']));
    expect(result.map((item) => item.id).toSet().length, result.length);
  });

  test('regeneration with non-positive length leaves queue unchanged', () {
    final current = song('current');

    final result = service().regenerate(
      candidates: [song('one')],
      currentQueue: [current],
      profile: profile,
      history: const [],
      length: 0,
    );

    expect(result.map((item) => item.id), ['current']);
  });

  test('append remains unique across repeated calls', () {
    final current = song('current');

    final first = service().append(
      candidates: [song('one', artist: 'Other'), song('two', artist: 'Third')],
      currentQueue: [current],
      profile: profile,
      history: const [],
      additional: 1,
    );

    final second = service().append(
      candidates: [
        song('one', artist: 'Other'),
        song('two', artist: 'Third'),
        song('three', artist: 'Fourth'),
      ],
      currentQueue: first,
      profile: profile,
      history: const [],
      additional: 1,
    );

    expect(second.map((item) => item.id).toSet().length, second.length);
    expect(second.length, 3);
  });

  test('transition-aware queue still avoids consecutive artists', () {
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

  test('empty candidate pool produces an empty addition', () {
    final current = song('current');

    final result = service().append(
      candidates: const [],
      currentQueue: [current],
      profile: profile,
      history: const [],
      additional: 3,
    );

    expect(result.map((item) => item.id), ['current']);
  });
}
