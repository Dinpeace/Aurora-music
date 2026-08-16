import 'package:flutter_test/flutter_test.dart';
import 'package:aurora_music/data/models/online/online_song.dart';
import 'package:aurora_music/data/services/mood_energy_service.dart';
import 'package:aurora_music/data/services/session_intelligence_service.dart';

OnlineSong _song(String id, String title, String artist, String album) {
  return OnlineSong(
    id: id,
    title: title,
    artist: artist,
    album: album,
    artwork: '',
    streamUrl: '',
    duration: const Duration(minutes: 3),
  );
}

void main() {
  group('MoodEnergyService', () {
    test('exposes all supported mood profiles', () {
      final service = MoodEnergyService(
        session: SessionIntelligenceService(),
      );

      expect(service.profiles, hasLength(6));
      expect(service.profiles, contains(MoodProfile.night));
      expect(MoodProfile.energetic.title, 'High Energy');
    });

    test('ranks matching mood keywords above unrelated songs', () {
      final service = MoodEnergyService(
        session: SessionIntelligenceService(),
      );

      final ranked = service.rank(
        <OnlineSong>[
          _song('1', 'Quiet Piano', 'Calm Artist', 'Ambient Chill'),
          _song('2', 'Festival Remix', 'Dance Artist', 'EDM Party'),
        ],
        MoodProfile.energetic,
      );

      expect(ranked.first.id, '2');
    });

    test('excluded IDs never appear in ranked results', () {
      final service = MoodEnergyService(
        session: SessionIntelligenceService(),
      );

      final ranked = service.rank(
        <OnlineSong>[
          _song('1', 'Night Chill', 'Artist', 'Night'),
          _song('2', 'Midnight', 'Artist', 'Night'),
        ],
        MoodProfile.night,
        excludedIds: const <String>{'1'},
      );

      expect(ranked.map((song) => song.id), isNot(contains('1')));
      expect(ranked, hasLength(1));
    });
  });
}
