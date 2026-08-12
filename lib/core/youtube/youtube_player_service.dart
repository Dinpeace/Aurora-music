import 'dart:async';

import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class YoutubePlayerService {
  YoutubePlayerService({
    bool autoPlay = false,
  })  : _autoPlay = autoPlay,
        controller = YoutubePlayerController(
          params: const YoutubePlayerParams(
            showControls: true,
            showFullscreenButton: true,
            mute: false,
            privacyEnhancedMode: true,
          ),
        ) {
    _valueSubscription = controller.stream.listen(_handleValue);
  }

  final YoutubePlayerController controller;

  final bool _autoPlay;

  late final StreamSubscription<YoutubePlayerValue> _valueSubscription;

  bool _disposed = false;

  /// Current YouTube player state.
  Stream<YoutubePlayerValue> get valueStream => controller.stream;

  /// Current YouTube video position and buffering state.
  Stream<YoutubeVideoState> get videoStateStream =>
      controller.videoStateStream;

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

    await controller.loadVideoById(videoId: id);

    if (!_autoPlay) {
      await controller.pauseVideo();
    }
  }

  Future<void> play() async {
    _checkDisposed();
    await controller.playVideo();
  }

  Future<void> pause() async {
    _checkDisposed();
    await controller.pauseVideo();
  }

  Future<void> togglePlayPause() async {
    _checkDisposed();

    if (controller.value.playerState == PlayerState.playing) {
      await controller.pauseVideo();
    } else {
      await controller.playVideo();
    }
  }

  Future<void> seek(Duration position) async {
    _checkDisposed();

    await controller.seekTo(
      seconds: position.inMilliseconds / 1000,
      allowSeekAhead: true,
    );
  }

  Future<Duration> getCurrentPosition() async {
    _checkDisposed();

    final seconds = await controller.currentTime;

    return Duration(
      milliseconds: (seconds * 1000).round(),
    );
  }

  Future<Duration> getDuration() async {
    _checkDisposed();

    final seconds = await controller.duration;

    return Duration(
      milliseconds: (seconds * 1000).round(),
    );
  }

  YoutubeMetaData get metadata => controller.metadata;

  PlayerState get playerState => controller.value.playerState;

  bool get isPlaying =>
      controller.value.playerState == PlayerState.playing;

  bool get hasError => controller.value.hasError;

  YoutubeError get error => controller.value.error;

  void _handleValue(YoutubePlayerValue value) {
    // The Aurora PlayerController will consume this later.
    //
    // This service intentionally remains independent from
    // the existing just_audio player until the standalone
    // YouTube playback test is complete.
  }

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

    await _valueSubscription.cancel();
    await controller.close();
  }
}
