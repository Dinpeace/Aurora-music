import '../models/song.dart';
import 'listening_history_service.dart';

/// Small player-facing adapter for recording meaningful playback events.
///
/// PlayerController remains responsible for playback. This bridge only records
/// play/skip metadata and can be called from whichever player callbacks Aurora
/// already uses.
class PlaybackIntelligenceBridge {
  PlaybackIntelligenceBridge({
    required ListeningHistoryService history,
    this.minimumListenForPlay = const Duration(seconds: 10),
    this.skipBefore = const Duration(seconds: 30),
  }) : _history = history;

  final ListeningHistoryService _history;
  final Duration minimumListenForPlay;
  final Duration skipBefore;

  Future<void> recordStarted(Song song) async {
    await _history.initialize();
    await _history.recordPlay(
      song: song,
      position: Duration.zero,
      duration: song.duration,
    );
  }

  Future<void> recordProgress({
    required Song song,
    required Duration position,
  }) async {
    if (position < minimumListenForPlay) return;

    await _history.initialize();
    await _history.recordPlay(
      song: song,
      position: position,
      duration: song.duration,
    );
  }

  Future<void> recordCompleted(Song song) async {
    await _history.initialize();
    await _history.recordPlay(
      song: song,
      position: song.duration,
      duration: song.duration,
    );
  }

  Future<void> recordSkipped({
    required Song song,
    required Duration position,
  }) async {
    if (position > skipBefore) return;

    await _history.initialize();
    await _history.recordSkip(
      song: song,
      position: position,
      duration: song.duration,
    );
  }

  bool shouldCountAsSkip(Duration position) {
    return position <= skipBefore;
  }

  bool shouldCountAsMeaningfulListen(Duration position) {
    return position >= minimumListenForPlay;
  }
}
