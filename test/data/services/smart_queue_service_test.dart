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

  OnlineSong song(String id) => OnlineSong(
        id: id,
        title: id,
        artist: 'Aurora',
        album: 'Album',
        artwork: '',
        streamUrl: 'https://example.com/$id',
        duration: const Duration(minutes: 3),
      );

  test('builds adaptive queue without current songs', () {
    final current = song('current');

    final result = service().build(
      candidates: [current, song('one'), song('two'), song('three')],
      currentQueue: [current],
      profile: profile,
      history: const [],
      length: 2,
    );

    expect(result.map((s) => s.id), isNot(contains('current')));
  });

  test('append preserves existing queue', () {
    final current = song('current');

    final result = service().append(
      candidates: [song('one'), song('two')],
      currentQueue: [current],
      profile: profile,
      history: const [],
      additional: 1,
    );

    expect(result.first.id, 'current');
    expect(result.length, 2);
  });
}
