import 'package:flutter_test/flutter_test.dart';
import 'package:aurora_music/data/models/listening_history_entry.dart';
import 'package:aurora_music/data/models/online/online_song.dart';
import 'package:aurora_music/data/models/song.dart';
import 'package:aurora_music/data/services/adaptive_recommendation_service.dart';
import 'package:aurora_music/data/services/taste_profile_service.dart';

void main() {
  const emptyProfile = TasteProfile(
    genres: {},
    artists: {},
    albums: {},
    favoriteArtists: {},
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

  Song local(String id, {String artist = 'Aurora'}) => Song(
        id: id,
        title: id,
        artist: artist,
        album: 'Album',
        artwork: '',
        audioUrl: 'https://example.com/$id.mp3',
        duration: const Duration(minutes: 3),
      );

  ListeningHistoryEntry entry({
    required String id,
    required DateTime lastPlayed,
    int plays = 0,
    int skips = 0,
    String artist = 'Aurora',
  }) =>
      ListeningHistoryEntry(
        song: local(id, artist: artist),
        lastPlayed: lastPlayed,
        playCount: plays,
        position: const Duration(minutes: 2),
        duration: const Duration(minutes: 3),
        skipCount: skips,
      );

  test('recent taste is weighted more strongly than old taste', () {
    final service = AdaptiveRecommendationService(
      longTermWeight: 0.65,
      longTermDecayDays: 180,
    );

    final now = DateTime.now();
    final result = service.rank(
      candidates: [
        online('recent', artist: 'Recent Artist'),
        online('old', artist: 'Old Artist'),
      ],
      profile: emptyProfile,
      history: [
        entry(
          id: 'recent',
          artist: 'Recent Artist',
          lastPlayed: now.subtract(const Duration(days: 2)),
          plays: 3,
        ),
        entry(
          id: 'old',
          artist: 'Old Artist',
          lastPlayed: now.subtract(const Duration(days: 900)),
          plays: 3,
        ),
      ],
      limit: 2,
    );

    expect(result.first.id, 'recent');
  });

  test('long-term preferences retain a non-zero floor after a long break', () {
    final service = AdaptiveRecommendationService(
      longTermWeight: 1.0,
      longTermDecayDays: 180,
    );

    final result = service.rank(
      candidates: [
        online('old-favorite', artist: 'Aurora'),
        online('new', artist: 'Other'),
      ],
      profile: const TasteProfile(
        genres: {},
        artists: {'aurora': 10},
        albums: {},
        favoriteArtists: {},
        favoriteIds: {},
      ),
      history: [
        entry(
          id: 'old-favorite',
          artist: 'Aurora',
          lastPlayed: DateTime.now().subtract(const Duration(days: 1000)),
          plays: 1,
        ),
      ],
      limit: 2,
    );

    expect(result.map((song) => song.id), contains('old-favorite'));
  });

  test('repeated recent skips still dominate long-term preference', () {
    final service = AdaptiveRecommendationService();

    final result = service.rank(
      candidates: [
        online('skipped', artist: 'Aurora'),
        online('fresh', artist: 'Other'),
      ],
      profile: const TasteProfile(
        genres: {},
        artists: {'aurora': 30},
        albums: {},
        favoriteArtists: {'aurora'},
        favoriteIds: {},
      ),
      history: [
        entry(
          id: 'skipped',
          artist: 'Aurora',
          lastPlayed: DateTime.now(),
          plays: 2,
          skips: 3,
        ),
      ],
      limit: 2,
    );

    expect(result.first.id, 'fresh');
  });

  test('excluded IDs remain excluded with time decay enabled', () {
    final service = AdaptiveRecommendationService();

    final result = service.rank(
      candidates: [
        online('old'),
        online('fresh', artist: 'Other'),
      ],
      profile: emptyProfile,
      history: [
        entry(
          id: 'old',
          lastPlayed: DateTime.now().subtract(const Duration(days: 600)),
          plays: 10,
        ),
      ],
      excludedIds: {'old'},
      limit: 2,
    );

    expect(result.map((song) => song.id), ['fresh']);
  });
}
