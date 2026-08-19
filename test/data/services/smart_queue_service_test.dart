import 'package:flutter_test/flutter_test.dart';
import 'package:aurora_music/data/models/listening_history_entry.dart';
import 'package:aurora_music/data/models/online/online_song.dart';
import 'package:aurora_music/data/models/song.dart';
import 'package:aurora_music/data/services/adaptive_recommendation_service.dart';
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

  ListeningHistoryEntry entry({
    required String id,
    DateTime? lastPlayed,
    int plays = 0,
    int skips = 0,
  }) =>
      ListeningHistoryEntry(
        song: local(id),
        lastPlayed: lastPlayed ?? DateTime(2026, 1, 1),
        playCount: plays,
        position: const Duration(minutes: 2),
        duration: const Duration(minutes: 3),
        skipCount: skips,
      );

  test('recent skips still strongly suppress a track', () {
    final service = AdaptiveRecommendationService();

    final result = service.rank(
      candidates: [
        online('skipped'),
        online('fresh', artist: 'Other', album: 'Other'),
      ],
      profile: profile,
      history: [
        entry(id: 'skipped', plays: 1, skips: 3),
      ],
      limit: 2,
    );

    expect(result.first.id, 'fresh');
  });

  test('long-term profile contributes a stable preference signal', () {
    final service = AdaptiveRecommendationService();

    final result = service.rank(
      candidates: [
        online('stable', artist: 'Aurora', album: 'Stable'),
        online('unknown', artist: 'Other', album: 'Other'),
      ],
      profile: const TasteProfile(
        genres: {},
        artists: {},
        albums: {},
        favoriteArtists: {},
        favoriteIds: {},
      ),
      history: [
        entry(
          id: 'stable',
          plays: 8,
          lastPlayed: DateTime(2025, 1, 1),
        ),
      ],
      limit: 2,
    );

    expect(result.first.id, 'stable');
  });

  test('recent negative feedback does not erase stable taste forever', () {
    final service = AdaptiveRecommendationService();

    final result = service.rank(
      candidates: [
        online('stable', artist: 'Aurora', album: 'Stable'),
        online('fresh', artist: 'Other', album: 'Other'),
      ],
      profile: const TasteProfile(
        genres: {},
        artists: {},
        albums: {},
        favoriteArtists: {'aurora'},
        favoriteIds: {},
      ),
      history: [
        entry(id: 'stable', plays: 8, skips: 1),
      ],
      limit: 2,
    );

    expect(result, hasLength(2));
    expect(result.map((song) => song.id), contains('stable'));
  });

  test('excluded IDs remain excluded with long-term learning enabled', () {
    final service = AdaptiveRecommendationService();

    final result = service.rank(
      candidates: [
        online('stable'),
        online('fresh', artist: 'Other', album: 'Other'),
      ],
      profile: profile,
      history: [
        entry(id: 'stable', plays: 10),
      ],
      excludedIds: {'stable'},
      limit: 2,
    );

    expect(result.map((song) => song.id), ['fresh']);
  });
}
