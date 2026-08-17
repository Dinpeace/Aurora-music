import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aurora_music/data/models/song.dart';
import 'package:aurora_music/data/services/listening_history_service.dart';
import 'package:aurora_music/data/services/playback_intelligence_bridge.dart';

void main() {
  Song song() {
    return const Song(
      id: 'song-1',
      title: 'Aurora',
      artist: 'Aurora',
      album: 'Album',
      artwork: null,
      audioUrl: '/music/aurora.mp3',
      duration: Duration(minutes: 3),
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('records completed playback', () async {
    final history = ListeningHistoryService();
    final bridge = PlaybackIntelligenceBridge(history: history);

    await bridge.recordCompleted(song());

    expect(history.entries, hasLength(1));
    expect(history.entries.first.playCount, 1);
    expect(history.entries.first.position, song().duration);
  });

  test('records early skips as skips', () async {
    final history = ListeningHistoryService();
    final bridge = PlaybackIntelligenceBridge(
      history: history,
      skipBefore: const Duration(seconds: 30),
    );

    await bridge.recordSkipped(
      song: song(),
      position: const Duration(seconds: 12),
    );

    expect(history.entries, hasLength(1));
    expect(history.entries.first.skipCount, 1);
  });

  test('does not record progress before meaningful-listen threshold', () async {
    final history = ListeningHistoryService();
    final bridge = PlaybackIntelligenceBridge(
      history: history,
      minimumListenForPlay: const Duration(seconds: 10),
    );

    await bridge.recordProgress(
      song: song(),
      position: const Duration(seconds: 5),
    );

    expect(history.entries, isEmpty);
  });

  test('exposes playback thresholds', () {
    final bridge = PlaybackIntelligenceBridge(
      history: ListeningHistoryService(),
      minimumListenForPlay: const Duration(seconds: 10),
      skipBefore: const Duration(seconds: 30),
    );

    expect(
      bridge.shouldCountAsMeaningfulListen(const Duration(seconds: 11)),
      isTrue,
    );
    expect(
      bridge.shouldCountAsSkip(const Duration(seconds: 20)),
      isTrue,
    );
    expect(
      bridge.shouldCountAsSkip(const Duration(seconds: 31)),
      isFalse,
    );
  });
}
