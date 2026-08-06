import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import 'package:aurora_music/data/models/song.dart';

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

  const PlayerState({
    this.currentSong,
    this.queue = const [],
    this.isPlaying = false,
    this.isShuffleEnabled = false,
    this.repeatMode = PlayerRepeatMode.off,
    this.position = Duration.zero,
  });

  PlayerState copyWith({
    Song? currentSong,
    List<Song>? queue,
    bool? isPlaying,
    bool? isShuffleEnabled,
    PlayerRepeatMode? repeatMode,
    Duration? position,
  }) {
    return PlayerState(
      currentSong: currentSong ?? this.currentSong,
      queue: queue ?? this.queue,
      isPlaying: isPlaying ?? this.isPlaying,
      isShuffleEnabled:
          isShuffleEnabled ?? this.isShuffleEnabled,
      repeatMode: repeatMode ?? this.repeatMode,
      position: position ?? this.position,
    );
  }
}

class PlayerController extends StateNotifier<PlayerState> {
  PlayerController() : super(const PlayerState()) {
    _player.positionStream.listen((position) {
      state = state.copyWith(position: position);
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
      await _player.setFilePath(song.audioUrl);

      await _player.play();

      state = state.copyWith(
        currentSong: song,
        queue: queue,
        isPlaying: true,
        position: Duration.zero,
      );
    } catch (e) {
      debugPrint('Playback Error: $e');
    }
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

  Future<void> previousSong() async {
    if (state.currentSong == null || state.queue.isEmpty) {
      return;
    }

    final index = state.queue.indexWhere(
      (song) => song.id == state.currentSong!.id,
    );

    if (index > 0) {
      await playSong(
        state.queue[index - 1],
        queue: state.queue,
      );
    }
  }

  Future<void> nextSong() async {
    if (state.currentSong == null || state.queue.isEmpty) {
      return;
    }

    final index = state.queue.indexWhere(
      (song) => song.id == state.currentSong!.id,
    );

    if (index < state.queue.length - 1) {
      await playSong(
        state.queue[index + 1],
        queue: state.queue,
      );
    }
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