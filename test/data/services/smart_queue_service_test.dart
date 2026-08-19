import 'package:flutter_test/flutter_test.dart';
import 'package:aurora_music/data/models/online/online_song.dart';
import 'package:aurora_music/data/services/adaptive_recommendation_service.dart';
import 'package:aurora_music/data/services/mood_energy_service.dart';
import 'package:aurora_music/data/services/session_intelligence_service.dart';
import 'package:aurora_music/data/services/smart_queue_service.dart';
import 'package:aurora_music/data/services/taste_profile_service.dart';

void main() {
  const profile = TasteProfile(
    genres: {'pop': 10},
    artists: {'aurora': 20},
    albums: {'album': 5},
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

  final service = SmartQueueService(
    adaptive: AdaptiveRecommendationService(),
    mood: MoodEnergyService(
      session: SessionIntelligenceService(),
    ),
    session: SessionIntelligenceService(),
  );

  test('balanced mode preserves normal recommendation behavior', () {
    final result = service.build(
      candidates: [
        song('one'),
        song('two', artist: 'Other', album: 'Other'),
      ],
      profile: profile,
      history: const [],
      mode: ListeningMode.balanced,
      length: 2,
    );

    expect(result, hasLength(2));
  });

  test('favorites mode prioritizes favorite artists', () {
    final result = service.build(
      candidates: [
        song('other', artist: 'Other', album: 'Other'),
        song('favorite', artist: 'Aurora', album: 'Favorite'),
      ],
      profile: profile,
      history: const [],
      mode: ListeningMode.favorites,
      length: 1,
    );

    expect(result.first.id, 'favorite');
  });

  test('discovery mode can prioritize an unknown artist', () {
    final result = service.build(
      candidates: [
        song('favorite', artist: 'Aurora', album: 'Album'),
        song('new', artist: 'Unknown', album: 'New Album'),
      ],
      profile: profile,
      history: const [],
      mode: ListeningMode.discovery,
      length: 1,
    );

    expect(result.first.id, 'new');
  });

  test('focus mode recognizes focus-oriented metadata', () {
    final result = service.build(
      candidates: [
        song('normal', artist: 'Other', album: 'Pop'),
        song('focus', artist: 'Other', album: 'Ambient Focus'),
      ],
      profile: profile,
      history: const [],
      mode: ListeningMode.focus,
      length: 1,
    );

    expect(result.first.id, 'focus');
  });

  test('chill mode recognizes chill-oriented metadata', () {
    final result = service.build(
      candidates: [
        song('normal', artist: 'Other', album: 'Pop'),
        song('chill', artist: 'Other', album: 'Acoustic Chill'),
      ],
      profile: profile,
      history: const [],
      mode: ListeningMode.chill,
      length: 1,
    );

    expect(result.first.id, 'chill');
  });

  test('changing mode does not mutate the taste profile', () {
    final before = profile;

    service.build(
      candidates: [
        song('one'),
        song('two', artist: 'Other'),
      ],
      profile: profile,
      history: const [],
      mode: ListeningMode.discovery,
      length: 2,
    );

    expect(profile, equals(before));
    expect(profile.favoriteArtists, contains('aurora'));
  });

  test('mode-aware regeneration still excludes current queue', () {
    final current = song('current');

    final result = service.regenerate(
      candidates: [
        current,
        song('next', artist: 'Other', album: 'Other'),
      ],
      currentQueue: [current],
      profile: profile,
      history: const [],
      mode: ListeningMode.discovery,
      length: 1,
    );

    expect(result.map((item) => item.id), ['current', 'next']);
  });
}
