import 'package:flutter_test/flutter_test.dart';
import 'package:aurora_music/data/models/listening_history_entry.dart';
import 'package:aurora_music/data/models/online/online_song.dart';
import 'package:aurora_music/data/models/song.dart';
import 'package:aurora_music/data/services/adaptive_recommendation_service.dart';
import 'package:aurora_music/data/services/mood_energy_service.dart';
import 'package:aurora_music/data/services/session_intelligence_service.dart';
import 'package:aurora_music/data/services/smart_queue_service.dart';
import 'package:aurora_music/data/services/taste_profile_service.dart';

void main() {
  const profile = TasteProfile(
    genres: {'pop': 10},
    artists: {'aurora': 20},
    albums: {},
    favoriteArtists: {'aurora'},
    favoriteIds: {},
  );

  OnlineSong online(
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

  Song local(String id) => Song(
        id: id,
        title: id,
        artist: 'Aurora',
        album: 'Album',
        artwork: '',
        audioUrl: 'https://example.com/$id.mp3',
        duration: const Duration(minutes: 3),
      );

  ListeningHistoryEntry historyEntry({
    required String id,
    int plays = 0,
    int skips = 0,
  }) =>
      ListeningHistoryEntry(
        song: local(id),
        lastPlayed: DateTime(2026, 1, 1),
        playCount: plays,
        position: const Duration(minutes: 1),
        duration: const Duration(minutes: 3),
        skipCount: skips,
      );

  test('repeated skips push a familiar track behind a fresh candidate', () {
    final service = AdaptiveRecommendationService(
      explorationWeight: 0.18,
      repetitionPenalty: 0.35,
      skipPenalty: 2.5,
    );

    final result = service.rank(
      candidates: [
        online('skipped'),
        online('fresh', artist: 'Other', album: 'Other'),
      ],
      profile: profile,
      history: [
        historyEntry(id: 'skipped', plays: 1, skips: 3),
      ],
      limit: 2,
    );

    expect(result.first.id, 'fresh');
  });

  test('successful plays receive a positive adaptive signal', () {
    final service = AdaptiveRecommendationService();

    final result = service.rank(
      candidates: [
        online('played'),
        online('fresh', artist: 'Other', album: 'Other'),
      ],
      profile: profile,
      history: [
        historyEntry(id: 'played', plays: 4),
      ],
      limit: 2,
    );

    expect(result, hasLength(2));
    expect(result.map((song) => song.id), contains('played'));
  });

  test('adaptive history still respects excluded IDs', () {
    final service = AdaptiveRecommendationService();

    final result = service.rank(
      candidates: [
        online('one'),
        online('two', artist: 'Other'),
      ],
      profile: profile,
      history: [
        historyEntry(id: 'one', skips: 4),
      ],
      excludedIds: {'two'},
      limit: 5,
    );

    expect(result.map((song) => song.id), ['one']);
  });

  test('queue regeneration uses feedback-aware ranking', () {
    final service = SmartQueueService(
      adaptive: AdaptiveRecommendationService(),
      mood: MoodEnergyService(
        session: SessionIntelligenceService(),
      ),
    );

    final result = service.regenerate(
      candidates: [
        online('skipped'),
        online('fresh', artist: 'Other', album: 'Other'),
      ],
      currentQueue: const [],
      profile: profile,
      history: [
        historyEntry(id: 'skipped', plays: 1, skips: 3),
      ],
      length: 2,
    );

    expect(result.first.id, 'fresh');
  });
}
