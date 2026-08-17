import 'package:flutter_test/flutter_test.dart';

import 'package:aurora_music/data/models/listening_history_entry.dart';
import 'package:aurora_music/data/models/song.dart';
import 'package:aurora_music/data/services/listening_insights_service.dart';
import 'package:aurora_music/data/services/taste_profile_service.dart';

void main() {
  final service = ListeningInsightsService();

  Song song(String id, String artist, String album) {
    return Song(
      id: id,
      title: id,
      artist: artist,
      album: album,
      audioUrl: '/music/$id.mp3',
      duration: const Duration(minutes: 3),
    );
  }

  ListeningHistoryEntry entry({
    required Song song,
    int plays = 1,
    int skips = 0,
    Duration position = const Duration(minutes: 3),
  }) {
    return ListeningHistoryEntry(
      song: song,
      lastPlayed: DateTime.now(),
      playCount: plays,
      position: position,
      duration: song.duration,
      skipCount: skips,
    );
  }

  const profile = TasteProfile(
    genres: {'pop': 12, 'rock': 8},
    artists: {'aurora': 10},
    albums: {'album': 5},
    favoriteArtists: {'aurora'},
    favoriteIds: {'one'},
  );

  test('summarizes play and skip totals', () {
    final result = service.summarize(
      history: [
        entry(song: song('one', 'Aurora', 'Album'), plays: 4, skips: 1),
        entry(song: song('two', 'Other', 'Other Album'), plays: 2, skips: 2),
      ],
      profile: profile,
    );

    expect(result.totalTracks, 2);
    expect(result.totalPlays, 6);
    expect(result.totalSkips, 3);
    expect(result.skipRate, closeTo(0.5, 0.001));
  });

  test('ranks top artists by play count', () {
    final result = service.summarize(
      history: [
        entry(song: song('one', 'Aurora', 'Album'), plays: 5),
        entry(song: song('two', 'Aurora', 'Other'), plays: 3),
        entry(song: song('three', 'Other', 'Album'), plays: 7),
      ],
      profile: profile,
    );

    expect(result.topArtists.first.name, 'aurora');
    expect(result.topArtists.first.plays, 8);
  });

  test('reports completion rate from meaningful positions', () {
    final result = service.summarize(
      history: [
        entry(
          song: song('one', 'Aurora', 'Album'),
          position: const Duration(minutes: 3),
        ),
        entry(
          song: song('two', 'Other', 'Other'),
          position: const Duration(seconds: 30),
        ),
      ],
      profile: profile,
    );

    expect(result.completionRate, closeTo(0.5, 0.001));
    expect(result.listeningTime, const Duration(minutes: 3, seconds: 30));
  });

  test('preserves profile-derived top genres and favorite counts', () {
    final result = service.summarize(
      history: const [],
      profile: profile,
    );

    expect(result.topGenres, ['pop', 'rock']);
    expect(result.favoriteArtistCount, 1);
    expect(result.favoriteTrackCount, 1);
    expect(result.hasData, isFalse);
  });
}
