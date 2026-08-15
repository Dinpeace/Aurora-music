import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class YoutubePlayerService {
  YoutubePlayerService({
    bool autoPlay = true,
  })  : _autoPlay = autoPlay,
        controller = YoutubePlayerController(
          params: const YoutubePlayerParams(
            showControls: true,
            showFullscreenButton: true,
            mute: false,
            privacyEnhancedMode: true,
            playsInline: true,
          ),
        ) {
    _valueSubscription = controller.stream.listen(
      _handleValue,
    );
  }

  final YoutubePlayerController controller;
  final bool _autoPlay;

  late final StreamSubscription<YoutubePlayerValue>
      _valueSubscription;

  bool _disposed = false;

  // ---------------------------------------------------------------------------
  // STREAMS
  // ---------------------------------------------------------------------------

  Stream<YoutubePlayerValue> get valueStream =>
      controller.stream;

  Stream<YoutubeVideoState> get videoStateStream =>
      controller.videoStateStream;

  // ---------------------------------------------------------------------------
  // LOAD VIDEO
  // ---------------------------------------------------------------------------

  Future<void> load(String videoId) async {
    _checkDisposed();

    final id = videoId.trim();

    if (id.isEmpty) {
      throw ArgumentError.value(
        videoId,
        'videoId',
        'YouTube video ID cannot be empty.',
      );
    }

    debugPrint(
      'Aurora YouTube: loading video $id',
    );

    try {
      if (_autoPlay) {
        await controller.loadVideoById(
          videoId: id,
        );

        debugPrint(
          'Aurora YouTube: loadVideoById completed',
        );
      } else {
        await controller.cueVideoById(
          videoId: id,
        );

        debugPrint(
          'Aurora YouTube: video cued',
        );
      }

      if (_disposed) {
        return;
      }

      await _waitForPlayerState();

      if (_disposed) {
        return;
      }

      final currentState =
          controller.value.playerState;

      debugPrint(
        'Aurora YouTube: player state after load: '
        '$currentState',
      );

      if (controller.value.hasError) {
        throw StateError(
          'YouTube player reported error: '
          '${controller.value.error}',
        );
      }
    } catch (error, stackTrace) {
      debugPrint(
        'Aurora YouTube: load failed: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      throw StateError(
        'YouTube playback failed for "$id": $error',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // WAIT FOR PLAYER STATE
  // ---------------------------------------------------------------------------

  Future<void> _waitForPlayerState() async {
    const timeout = Duration(seconds: 8);

    final completer = Completer<void>();

    late StreamSubscription<YoutubePlayerValue>
        subscription;

    Timer? timer;

    void finish() {
      if (completer.isCompleted) {
        return;
      }

      timer?.cancel();
      subscription.cancel();

      completer.complete();
    }

    subscription = controller.stream.listen(
      (value) {
        if (value.hasError) {
          finish();
          return;
        }

        /*
         * UNKNOWN means the iframe hasn't reported a useful
         * player state yet.
         *
         * Any other state means YouTube has responded.
         */
        if (value.playerState !=
            PlayerState.unknown) {
          finish();
        }
      },
    );

    timer = Timer(
      timeout,
      finish,
    );

    /*
     * Check the current state immediately.
     */
    final current =
        controller.value;

    if (current.hasError ||
        current.playerState !=
            PlayerState.unknown) {
      finish();
    }

    await completer.future;
  }

  // ---------------------------------------------------------------------------
  // PLAY
  // ---------------------------------------------------------------------------

  Future<void> play() async {
    _checkDisposed();

    debugPrint(
      'Aurora YouTube: play',
    );

    await controller.playVideo();
  }

  // ---------------------------------------------------------------------------
  // PAUSE
  // ---------------------------------------------------------------------------

  Future<void> pause() async {
    _checkDisposed();

    debugPrint(
      'Aurora YouTube: pause',
    );

    await controller.pauseVideo();
  }

  // ---------------------------------------------------------------------------
  // TOGGLE
  // ---------------------------------------------------------------------------

  Future<void> togglePlayPause() async {
    _checkDisposed();

    final currentState =
        controller.value.playerState;

    debugPrint(
      'Aurora YouTube: toggle '
      'current=$currentState',
    );

    if (currentState ==
        PlayerState.playing) {
      await controller.pauseVideo();
    } else {
      await controller.playVideo();
    }
  }

  // ---------------------------------------------------------------------------
  // SEEK
  // ---------------------------------------------------------------------------

  Future<void> seek(
    Duration position,
  ) async {
    _checkDisposed();

    final seconds =
        position.inMilliseconds / 1000.0;

    if (seconds < 0) {
      return;
    }

    debugPrint(
      'Aurora YouTube: seek '
      '${seconds.toStringAsFixed(2)}s',
    );

    await controller.seekTo(
      seconds: seconds,
      allowSeekAhead: true,
    );
  }

  // ---------------------------------------------------------------------------
  // CURRENT POSITION
  // ---------------------------------------------------------------------------

  Future<Duration> getCurrentPosition() async {
    _checkDisposed();

    final seconds =
        await controller.currentTime;

    if (seconds.isNaN ||
        seconds.isInfinite ||
        seconds < 0) {
      return Duration.zero;
    }

    return Duration(
      milliseconds:
          (seconds * 1000).round(),
    );
  }

  // ---------------------------------------------------------------------------
  // DURATION
  // ---------------------------------------------------------------------------

  Future<Duration> getDuration() async {
    _checkDisposed();

    final seconds =
        await controller.duration;

    if (seconds.isNaN ||
        seconds.isInfinite ||
        seconds <= 0) {
      return Duration.zero;
    }

    return Duration(
      milliseconds:
          (seconds * 1000).round(),
    );
  }

  // ---------------------------------------------------------------------------
  // PLAYER INFORMATION
  // ---------------------------------------------------------------------------

  YoutubeMetaData get metadata =>
      controller.metadata;

  PlayerState get playerState =>
      controller.value.playerState;

  bool get isPlaying =>
      controller.value.playerState ==
      PlayerState.playing;

  bool get hasError =>
      controller.value.hasError;

  YoutubeError get error =>
      controller.value.error;

  // ---------------------------------------------------------------------------
  // DEBUG
  // ---------------------------------------------------------------------------

  void _handleValue(
    YoutubePlayerValue value,
  ) {
    debugPrint(
      'Aurora YouTube: '
      'state=${value.playerState} '
      'error=${value.hasError ? value.error : "none"}',
    );
  }

  // ---------------------------------------------------------------------------
  // DISPOSE
  // ---------------------------------------------------------------------------

  void _checkDisposed() {
    if (_disposed) {
      throw StateError(
        'YoutubePlayerService has already been disposed.',
      );
    }
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }

    _disposed = true;

    debugPrint(
      'Aurora YouTube: disposing',
    );

    await _valueSubscription.cancel();
    await controller.close();
  }
}