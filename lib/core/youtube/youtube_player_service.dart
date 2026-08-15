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
            enableJavaScript: true,
            enableCaption: true,
            videoStateUpdateInterval: 100,
          ),
        );

  final YoutubePlayerController controller;
  final bool _autoPlay;

  bool _disposed = false;

  // ---------------------------------------------------------------------------
  // STREAMS
  // ---------------------------------------------------------------------------

  Stream<YoutubePlayerValue> get valueStream =>
      controller.stream;

  Stream<YoutubeVideoState> get videoStateStream =>
      controller.videoStateStream;

  // ---------------------------------------------------------------------------
  // LOAD
  // ---------------------------------------------------------------------------

  Future<void> load(String videoId) async {
    _checkDisposed();

    final id = _extractVideoId(videoId);

    if (id == null) {
      throw ArgumentError.value(
        videoId,
        'videoId',
        'Invalid YouTube video ID or URL.',
      );
    }

    debugPrint(
      'Aurora YouTube: loading [$id]',
    );

    try {
      if (_autoPlay) {
        await controller.loadVideoById(
          videoId: id,
        );
      } else {
        await controller.cueVideoById(
          videoId: id,
        );
      }

      if (_disposed) {
        return;
      }

      debugPrint(
        'Aurora YouTube: video command completed [$id]',
      );

      await _waitUntilReady();

      if (_disposed) {
        return;
      }

      final value = controller.value;

      debugPrint(
        'Aurora YouTube: '
        'state=${value.playerState} '
        'videoId=${value.metaData.videoId} '
        'error=${value.hasError ? value.error : 'none'}',
      );

      if (value.hasError) {
        throw StateError(
          'YouTube player reported error: ${value.error}',
        );
      }
    } catch (error, stackTrace) {
      debugPrint(
        'Aurora YouTube: failed to load [$id]: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // VIDEO ID EXTRACTION
  // ---------------------------------------------------------------------------

  String? _extractVideoId(String input) {
    final value = input.trim();

    if (value.isEmpty) {
      return null;
    }

    // Already a normal YouTube ID.
    final idPattern = RegExp(
      r'^[A-Za-z0-9_-]{11}$',
    );

    if (idPattern.hasMatch(value)) {
      return value;
    }

    // Accept full YouTube URLs as well.
    final converted =
        YoutubePlayerController.convertUrlToId(
      value,
    );

    if (converted == null) {
      return null;
    }

    final id = converted.trim();

    if (!idPattern.hasMatch(id)) {
      return null;
    }

    return id;
  }

  // ---------------------------------------------------------------------------
  // WAIT UNTIL YOUTUBE RESPONDS
  // ---------------------------------------------------------------------------

  Future<void> _waitUntilReady() async {
    final current = controller.value;

    if (current.hasError) {
      return;
    }

    if (current.playerState != PlayerState.unknown) {
      return;
    }

    final completer = Completer<void>();

    late StreamSubscription<YoutubePlayerValue> subscription;

    Timer? timeout;

    void finish() {
      if (completer.isCompleted) {
        return;
      }

      timeout?.cancel();
      subscription.cancel();

      completer.complete();
    }

    subscription = controller.stream.listen(
      (value) {
        if (value.hasError) {
          finish();
          return;
        }

        if (value.playerState != PlayerState.unknown) {
          finish();
        }
      },
    );

    timeout = Timer(
      const Duration(seconds: 10),
      finish,
    );

    try {
      await completer.future;
    } finally {
      timeout.cancel();

      if (!completer.isCompleted) {
        await subscription.cancel();
      }
    }
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

    final state = controller.value.playerState;

    debugPrint(
      'Aurora YouTube: toggle state=$state',
    );

    if (state == PlayerState.playing) {
      await controller.pauseVideo();
    } else {
      await controller.playVideo();
    }
  }

  // ---------------------------------------------------------------------------
  // SEEK
  // ---------------------------------------------------------------------------

  Future<void> seek(Duration position) async {
    _checkDisposed();

    var seconds =
        position.inMilliseconds / 1000.0;

    if (seconds < 0) {
      seconds = 0;
    }

    final duration = await getDuration();

    if (duration > Duration.zero &&
        position > duration) {
      seconds =
          duration.inMilliseconds / 1000.0;
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

    if (!seconds.isFinite || seconds < 0) {
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

    if (!seconds.isFinite || seconds <= 0) {
      return Duration.zero;
    }

    return Duration(
      milliseconds:
          (seconds * 1000).round(),
    );
  }

  // ---------------------------------------------------------------------------
  // STOP / RESET
  // ---------------------------------------------------------------------------

  Future<void> stop() async {
    _checkDisposed();

    debugPrint(
      'Aurora YouTube: stop',
    );

    await controller.stopVideo();
  }

  // ---------------------------------------------------------------------------
  // MUTE
  // ---------------------------------------------------------------------------

  Future<void> mute() async {
    _checkDisposed();

    await controller.mute();
  }

  // ---------------------------------------------------------------------------
  // UNMUTE
  // ---------------------------------------------------------------------------

  Future<void> unMute() async {
    _checkDisposed();

    await controller.unMute();
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

  bool get isPaused =>
      controller.value.playerState ==
      PlayerState.paused;

  bool get isBuffering =>
      controller.value.playerState ==
      PlayerState.buffering;

  bool get hasError =>
      controller.value.hasError;

  YoutubeError get error =>
      controller.value.error;

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

    await controller.close();
  }
}