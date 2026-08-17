import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aurora_music/data/models/song.dart';
import 'package:aurora_music/data/services/listening_history_service.dart';
import 'package:aurora_music/data/services/playback_intelligence_bridge.dart';
import 'package:aurora_music/data/services/player_intelligence_tracker.dart';

void main() {
  Song song(String id) {
    return Song(
      id: id,
      title: id,
      artist: 'Aurora',
      album: 'Album',
      audioUrl: '/music/$id.mp3',
      duration: const Duration(minutes: 3),
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('started song is recorded once', () async {
    final history = ListeningHistoryService();
    final tracker = PlayerIntelligenceTracker(
      bridge: PlaybackIntelligenceBridge(history: history),
    );

    final item = song('one');
    await tracker.onStarted(item);
    await tracker.onStarted(item);

    expect(history.entries, hasLength(1));
    expect(history.entries.first.playCount, 1);
  });

  test('meaningful listen is recorded once after threshold', () async {
    final history = ListeningHistoryService();
    final tracker = PlayerIntelligenceTracker(
      bridge: PlaybackIntelligenceBridge(
        history: history,
        minimumListenForPlay: const Duration(seconds: 10),
      ),
    );

    final item = song('one');
    await tracker.onStarted(item);
    await tracker.onPositionChanged(
      song: item,
      position: const Duration(seconds: 5),
    );
    await tracker.onPositionChanged(
      song: item,
      position: const Duration(seconds: 12),
    );
    await tracker.onPositionChanged(
      song: item,
      position: const Duration(seconds: 30),
    );

    expect(history.entries, hasLength(1));
    expect(history.entries.first.playCount, 2);
  });

  test('early skip records a skip signal', () async {
    final history = ListeningHistoryService();
    final tracker = PlayerIntelligenceTracker(
      bridge: PlaybackIntelligenceBridge(
        history: history,
        skipBefore: const Duration(seconds: 30),
      ),
    );

    final item = song('one');
    await tracker.onStarted(item);
    await tracker.onSkipped(
      song: item,
      position: const Duration(seconds: 8),
    );

    expect(history.entries, hasLength(1));
    expect(history.entries.first.skipCount, 1);
  });

  test('completion resets the active playback session', () async {
    final history = ListeningHistoryService();
    final tracker = PlayerIntelligenceTracker(
      bridge: PlaybackIntelligenceBridge(history: history),
    );

    final item = song('one');
    await tracker.onStarted(item);
    await tracker.onCompleted(item);

    await tracker.onStarted(item);

    expect(history.entries, hasLength(1));
    expect(history.entries.first.playCount, 3);
  });
}
