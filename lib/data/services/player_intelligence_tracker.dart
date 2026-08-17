import '../models/song.dart';
import 'playback_intelligence_bridge.dart';

/// Connects player lifecycle events to Aurora's local listening intelligence.
///
/// This class deliberately contains no audio-player dependency. PlayerController
/// only forwards playback events here, keeping intelligence persistence isolated
/// and testable.
class PlayerIntelligenceTracker {
  PlayerIntelligenceTracker({
    required PlaybackIntelligenceBridge bridge,
  }) : _bridge = bridge;

  final PlaybackIntelligenceBridge _bridge;

  String? _activeSongId;
  bool _meaningfulListenRecorded = false;

  Future<void> onStarted(Song song) async {
    if (_activeSongId == song.id) return;

    _activeSongId = song.id;
    _meaningfulListenRecorded = false;
    await _bridge.recordStarted(song);
  }

  Future<void> onPositionChanged({
    required Song song,
    required Duration position,
  }) async {
    if (_activeSongId != song.id) {
      await onStarted(song);
    }

    if (!_meaningfulListenRecorded &&
        _bridge.shouldCountAsMeaningfulListen(position)) {
      _meaningfulListenRecorded = true;
      await _bridge.recordProgress(
        song: song,
        position: position,
      );
    }
  }

  Future<void> onCompleted(Song song) async {
    if (_activeSongId != song.id) {
      await onStarted(song);
    }

    await _bridge.recordCompleted(song);
    _activeSongId = null;
    _meaningfulListenRecorded = false;
  }

  Future<void> onSkipped({
    required Song song,
    required Duration position,
  }) async {
    if (_activeSongId != song.id) {
      await onStarted(song);
    }

    if (_bridge.shouldCountAsSkip(position)) {
      await _bridge.recordSkipped(
        song: song,
        position: position,
      );
    }

    _activeSongId = null;
    _meaningfulListenRecorded = false;
  }

  void reset() {
    _activeSongId = null;
    _meaningfulListenRecorded = false;
  }
}
