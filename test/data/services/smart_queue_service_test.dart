import 'package:flutter_test/flutter_test.dart';
import 'package:aurora_music/data/models/online/online_song.dart';
import 'package:aurora_music/data/models/song.dart';
import 'package:aurora_music/data/services/adaptive_recommendation_service.dart';
import 'package:aurora_music/data/services/mood_energy_service.dart';
import 'package:aurora_music/data/services/session_intelligence_service.dart';
import 'package:aurora_music/data/services/smart_queue_service.dart';
import 'package:aurora_music/data/services/taste_profile_service.dart';

void main() {
  SmartQueueService service({SessionIntelligenceService? session}) {
    final mood = MoodEnergyService(session: SessionIntelligenceService());
    return SmartQueueService(
      adaptive: AdaptiveRecommendationService(),
      mood: mood,
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

  OnlineSong song(String id, {String artist = 'Aurora'}) => OnlineSong(
        id: id,
        title: id,
        artist: artist,
        album: 'Album',
        artwork: '',
        streamUrl: 'https://example.com/$id',
        duration: const Duration(minutes: 3),
      );

  Song localSong(String id, {String artist = 'Aurora'}) => Song(
        id: id,
        title: id,
        artist: artist,
        album: 'Album',
        artwork: '',
        audioUrl: 'https://example.com/$id.mp3',
        duration: const Duration(minutes: 3),
      );

  test('session feedback changes queue order', () {
    final session = SessionIntelligenceService();
    session.recordPlay(localSong('played'));
    session.recordSkip('played');

    final result = service(session: session).build(
      candidates: [
        song('played'),
        song('fresh', artist: 'Other'),
      ],
      profile: profile,
      history: const [],
      length: 2,
    );

    expect(result.first.id, 'fresh');
  });

  test('without session service behavior remains compatible', () {
    final result = service().build(
      candidates: [song('one'), song('two')],
      profile: profile,
      history: const [],
      length: 2,
    );

    expect(result, hasLength(2));
  });

  test('append preserves existing queue with session adaptation', () {
    final session = SessionIntelligenceService();
    session.recordPlay(localSong('one'));

    final result = service(session: session).append(
      candidates: [song('one'), song('two')],
      currentQueue: [song('current')],
      profile: profile,
      history: const [],
      additional: 1,
    );

    expect(result.first.id, 'current');
    expect(result.length, 2);
  });
}
