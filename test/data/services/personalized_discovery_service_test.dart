import 'package:flutter_test/flutter_test.dart';

import 'package:aurora_music/data/models/listening_history_entry.dart';
import 'package:aurora_music/data/models/online/online_song.dart';
import 'package:aurora_music/data/models/song.dart';
import 'package:aurora_music/data/services/personalized_discovery_service.dart';
import 'package:aurora_music/data/services/taste_profile_service.dart';

void main() {
  OnlineSong song(String id, String artist, String album) {
    return OnlineSong(
      id: id,
      title: id,
      artist: artist,
      album: album,
      artwork: '',
      duration: const Duration(minutes: 3),
      streamUrl: 'https://example.com/$id',
    );
  }

  ListeningHistoryEntry historyEntry(OnlineSong online) {
    final local = Song(
      id: online.id,
      title: online.title,
      artist: online.artist,
      album: online.album,
      artwork: online.artwork,
      audioUrl: online.streamUrl,
      duration: online.duration,
    );

    return ListeningHistoryEntry(
      song: local,
      lastPlayed: DateTime(2026, 8, 17),
      playCount: 2,
      position: local.duration,
      duration: local.duration,
      skipCount: 0,
    );
  }

  final service = PersonalizedDiscoveryService();

  test('returns limited ranked discovery results', () {
    final familiar = song('familiar', 'Aurora', 'Known');
    final discovery = song('new', 'New Artist', 'New Album');

    final result = service.rank(
      candidates: [familiar, discovery],
      profile: const TasteProfile(
        genres: {},
        artists: {'aurora': 10},
        albums: {'known': 5},
        favoriteArtists: {'aurora'},
        favoriteIds: {'familiar'},
      ),
      history: [historyEntry(familiar)],
      limit: 1,
    );

    expect(result, hasLength(1));
  });

  test('can prefer an unseen candidate when the familiar track is recent', () {
    final familiar = song('familiar', 'Aurora', 'Known');
    final discovery = song('new', 'New Artist', 'New Album');

    final result = service.rank(
      candidates: [familiar, discovery],
      profile: const TasteProfile(
        genres: {},
        artists: {'aurora': 10},
        albums: {'known': 5},
        favoriteArtists: {'aurora'},
        favoriteIds: {'familiar'},
      ),
      history: [historyEntry(familiar)],
      limit: 2,
    );

    expect(result.first.id, 'new');
  });
}
