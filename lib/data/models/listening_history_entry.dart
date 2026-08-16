import 'song.dart';

class ListeningHistoryEntry {
  final Song song;
  final DateTime lastPlayed;
  final int playCount;
  final Duration position;
  final Duration duration;
  final int skipCount;

  const ListeningHistoryEntry({
    required this.song,
    required this.lastPlayed,
    required this.playCount,
    required this.position,
    required this.duration,
    this.skipCount = 0,
  });

  ListeningHistoryEntry copyWith({
    Song? song,
    DateTime? lastPlayed,
    int? playCount,
    Duration? position,
    Duration? duration,
    int? skipCount,
  }) {
    return ListeningHistoryEntry(
      song: song ?? this.song,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      playCount: playCount ?? this.playCount,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      skipCount: skipCount ?? this.skipCount,
    );
  }
}
