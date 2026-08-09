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

  double get progress {
    if (duration.inMilliseconds <= 0) {
      return 0;
    }

    return position.inMilliseconds /
        duration.inMilliseconds;
  }

  String get positionText => _format(position);

  String get durationText => _format(duration);

  static String _format(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

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
      isShuffleEnabled:
          isShuffleEnabled ?? this.isShuffleEnabled,
      repeatMode: repeatMode ?? this.repeatMode,
      position: position ?? this.position,
      duration: duration ?? this.duration,
    );
  }
}