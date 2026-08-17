import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aurora_music/data/models/song.dart';
import 'package:aurora_music/data/services/listening_history_service.dart';
import 'package:aurora_music/data/services/listening_intelligence_service.dart';
import 'package:aurora_music/data/services/taste_profile_service.dart';

void main() {
  Song song({
    required String id,
    required String artist,
    String album = 'Album',
  }) {
    return Song(
      id: id,
      title: 'Song $id',
      artist: artist,
      album: album,
      audioUrl: '/music/$id.mp3',
      duration: const Duration(minutes: 3),
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('builds a taste profile from persistent history and favorites', () async {
    final history = ListeningHistoryService();
    final taste = TasteProfileService();
    final intelligence = ListeningIntelligenceService(
      history: history,
      taste: taste,
    );

    await history.initialize();
    await history.recordPlay(
      song: song(id: 'one', artist: 'Aurora'),
      position: const Duration(minutes: 3),
    );
    await history.recordPlay(
      song: song(id: 'two', artist: 'Aurora'),
    );

    final profile = await intelligence.buildProfile(
      library: [
        song(id: 'one', artist: 'Aurora'),
        song(id: 'two', artist: 'Aurora'),
      ],
      favorites: [
        song(id: 'three', artist: 'The Weeknd'),
      ],
    );

    expect(profile.artists.containsKey('aurora'), isTrue);
    expect(profile.favoriteArtists, contains('the weeknd'));
    expect(profile.favoriteIds, contains('three'));
  });

  test('refreshes stale history metadata from the current library', () async {
    final history = ListeningHistoryService();
    final intelligence = ListeningIntelligenceService(
      history: history,
      taste: TasteProfileService(),
    );

    await history.initialize();
    await history.recordPlay(
      song: song(id: 'one', artist: 'Old Artist'),
    );

    final profile = await intelligence.buildProfile(
      library: [
        song(id: 'one', artist: 'Current Artist'),
      ],
    );

    expect(profile.artists.containsKey('current artist'), isTrue);
    expect(profile.artists.containsKey('old artist'), isFalse);
  });

  test('handles an empty library without failing', () async {
    final intelligence = ListeningIntelligenceService(
      history: ListeningHistoryService(),
      taste: TasteProfileService(),
    );

    final profile = await intelligence.buildProfile(
      library: const [],
    );

    expect(profile, isNotNull);
    expect(profile.isEmpty, isTrue);
  });
}
