import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../data/models/song.dart';

enum PlayerRepeatMode {
  off,
  all,
  one,
}

class PlayerState {
  final Song? currentSong;
  final List<Song> queue;
  final bool isPlaying;
  final bool isShuffleEnabled;
  final PlayerRepeatMode repeatMode;
  final Duration position;
  final Duration duration;

  const PlayerState({
    this.currentSong,
    this.queue = const [],
    this.isPlaying = false,
    this.isShuffleEnabled = false,
    this.repeatMode = PlayerRepeatMode.off,
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });

  PlayerState copyWith({
    Song? currentSong,
    List<Song>? queue,
    bool? isPlaying,
    bool? isShuffleEnabled,
    PlayerRepeatMode? repeatMode,
    Duration? position,
    Duration? duration,
  }) {
    return PlayerState(
      currentSong: currentSong ?? this.currentSong,
      queue: queue ?? this.queue,
      isPlaying: isPlaying ?? this.isPlaying,
      isShuffleEnabled: isShuffleEnabled ?? this.isShuffleEnabled,
      repeatMode: repeatMode ?? this.repeatMode,
      position: position ?? this.position,
      duration: duration ?? this.duration,
    );
  }
}

class PlayerController extends StateNotifier<PlayerState> {
  PlayerController() : super(const PlayerState()) {
    _player.positionStream.listen((position) {
      state = state.copyWith(position: position);
    });

    _player.durationStream.listen((duration) {
      state = state.copyWith(
        duration: duration ?? Duration.zero,
      );
    });

    _player.playerStateStream.listen((playerState) {
      state = state.copyWith(
        isPlaying: playerState.playing,
      );
    });
  }

  final AudioPlayer _player = AudioPlayer();

  Future<void> playSong(
    Song song, {
    List<Song> queue = const [],
  }) async {
    try {
      await _player.setUrl(song.audioUrl);

      state = state.copyWith(
        currentSong: song,
        queue: queue,
        position: Duration.zero,
        duration: song.duration,
      );

      await _player.play();
    } catch (_) {}
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  void toggleShuffle() {
    final enabled = !state.isShuffleEnabled;

    _player.setShuffleModeEnabled(enabled);

    state = state.copyWith(
      isShuffleEnabled: enabled,
    );
  }

  Future<void> cycleRepeatMode() async {
    switch (state.repeatMode) {
      case PlayerRepeatMode.off:
        await _player.setLoopMode(LoopMode.all);
        state = state.copyWith(
          repeatMode: PlayerRepeatMode.all,
        );
        break;

      case PlayerRepeatMode.all:
        await _player.setLoopMode(LoopMode.one);
        state = state.copyWith(
          repeatMode: PlayerRepeatMode.one,
        );
        break;

      case PlayerRepeatMode.one:
        await _player.setLoopMode(LoopMode.off);
        state = state.copyWith(
          repeatMode: PlayerRepeatMode.off,
        );
        break;
    }
  }

  Future<void> stop() async {
    await _player.stop();

    state = const PlayerState();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}

final playerControllerProvider =
    StateNotifierProvider<PlayerController, PlayerState>(
  (ref) => PlayerController(),
);