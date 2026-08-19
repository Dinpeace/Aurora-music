import 'package:flutter_test/flutter_test.dart';
import 'package:aurora_music/data/models/online/online_song.dart';
import 'package:aurora_music/data/services/adaptive_recommendation_service.dart';
import 'package:aurora_music/data/services/mood_energy_service.dart';
import 'package:aurora_music/data/services/session_intelligence_service.dart';
import 'package:aurora_music/data/services/smart_queue_service.dart';
import 'package:aurora_music/data/services/taste_profile_service.dart';

void main() {
  SmartQueueService service() {
    final mood = MoodEnergyService(session: SessionIntelligenceService());
    return SmartQueueService(
      adaptive: AdaptiveRecommendationService(),
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

  OnlineSong song(String id, {String artist = 'Aurora'}) => OnlineSong(
        id: id,
        title: id,
        artist: artist,
        album: 'Album',
        artwork: '',
        streamUrl: 'https://example.com/$id',
        duration: const Duration(minutes: 3),
      );

  test('build excludes every current queue item', () {
    final current = song('current');

    final result = service().build(
      candidates: [current, song('one'), song('two')],
      currentQueue: [current],
      profile: profile,
      history: const [],
      length: 2,
    );

    expect(result.map((s) => s.id), isNot(contains('current')));
    expect(result.length, 2);
  });

  test('append preserves existing queue and adds unique tracks', () {
    final current = song('current');

    final result = service().append(
      candidates: [current, song('one'), song('two')],
      currentQueue: [current],
      profile: profile,
      history: const [],
      additional: 2,
    );

    expect(result.first.id, 'current');
    expect(result.length, 3);
    expect(result.map((s) => s.id).toSet().length, result.length);
  });

  test('regenerate preserves current queue instead of replacing it', () {
    final current = song('current');

    final result = service().regenerate(
      candidates: [current, song('one'), song('two')],
      currentQueue: [current],
      profile: profile,
      history: const [],
      length: 1,
    );

    expect(result.first.id, 'current');
    expect(result.length, 2);
  });

  test('does not let one artist monopolize the queue', () {
    final result = service().build(
      candidates: [
        song('a1'),
        song('a2'),
        song('a3'),
        song('a4'),
        song('b1', artist: 'Other'),
      ],
      profile: profile,
      history: const [],
      length: 4,
    );

    final auroraCount =
        result.where((s) => s.artist == 'Aurora').length;

    expect(auroraCount, lessThanOrEqualTo(3));
  });
}
