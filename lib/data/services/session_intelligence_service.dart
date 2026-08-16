import '../models/online/online_song.dart';
import '../models/song.dart';

/// Keeps lightweight, in-memory signals for the current listening session.
///
/// This intentionally does not replace persistent listening history. It adds
/// short-lived signals that can react immediately to what the user is doing.
class SessionIntelligenceService {
  final Map<String, SessionTrackSignal> _signals =
      <String, SessionTrackSignal>{};

  DateTime _sessionStartedAt = DateTime.now();
  String? _lastSongId;

  DateTime get sessionStartedAt => _sessionStartedAt;

  Duration get sessionDuration => DateTime.now().difference(_sessionStartedAt);

  String? get lastSongId => _lastSongId;

  int get playedCount =>
      _signals.values.fold<int>(0, (total, item) => total + item.playCount);

  int get skippedCount =>
      _signals.values.fold<int>(0, (total, item) => total + item.skipCount);

  void reset() {
    _signals.clear();
    _sessionStartedAt = DateTime.now();
    _lastSongId = null;
  }

  void recordPlay(Song song) {
    final id = song.id.trim();
    if (id.isEmpty) return;

    final existing = _signals[id];
    final now = DateTime.now();

    _signals[id] = (existing ?? SessionTrackSignal.fromSong(song)).copyWith(
      song: song,
      playCount: (existing?.playCount ?? 0) + 1,
      lastPlayed: now,
    );
    _lastSongId = id;
  }

  void recordSkip(String songId) {
    final id = songId.trim();
    if (id.isEmpty) return;

    final existing = _signals[id];
    if (existing == null) {
      return;
    }

    _signals[id] = existing.copyWith(
      skipCount: existing.skipCount + 1,
      lastSkipped: DateTime.now(),
    );
  }

  void recordProgress({
    required String songId,
    required Duration position,
    required Duration duration,
  }) {
    final id = songId.trim();
    if (id.isEmpty) return;

    final existing = _signals[id];
    if (existing == null) return;

    final safeDuration = duration.inMilliseconds > 0
        ? duration
        : existing.duration;

    final progress = safeDuration.inMilliseconds > 0
        ? (position.inMilliseconds / safeDuration.inMilliseconds)
            .clamp(0.0, 1.0)
        : existing.completionRatio;

    _signals[id] = existing.copyWith(
      duration: safeDuration,
      lastPosition: position,
      completionRatio: progress,
    );
  }

  void recordCompletion(String songId) {
    final id = songId.trim();
    final existing = _signals[id];
    if (existing == null) return;

    _signals[id] = existing.copyWith(
      completionCount: existing.completionCount + 1,
      completionRatio: 1.0,
    );
  }

  SessionTrackSignal? signalFor(String songId) {
    return _signals[songId.trim()];
  }

  Set<String> get sessionSongIds =>
      Set<String>.unmodifiable(_signals.keys.toSet());

  Set<String> get rejectedSongIds => Set<String>.unmodifiable(
        _signals.entries
            .where((entry) => entry.value.skipCount > 0)
            .map((entry) => entry.key)
            .toSet(),
      );

  Map<String, int> get artistPlayCounts {
    final result = <String, int>{};
    for (final signal in _signals.values) {
      final artist = signal.artist.trim().toLowerCase();
      if (artist.isEmpty) continue;
      result[artist] = (result[artist] ?? 0) + signal.playCount;
    }
    return Map<String, int>.unmodifiable(result);
  }

  /// Scores an online candidate against the current session.
  double scoreOnlineSong(OnlineSong song) {
    final artist = song.artist.trim().toLowerCase();
    final album = song.album.trim().toLowerCase();
    final title = song.title.trim().toLowerCase();
    final signal = _signals[song.id];

    var score = 0.0;

    if (signal != null) {
      score += signal.playCount * 3.0;
      score += signal.completionCount * 1.5;
      score -= signal.skipCount * 8.0;
      score -= signal.completionRatio >= 0.85 ? 0.5 : 0.0;
    }

    final artistPlays = artistPlayCounts[artist] ?? 0;
    score += artistPlays * 2.5;

    if (artist.isNotEmpty && _lastSongId != null) {
      final last = _signals[_lastSongId!];
      if (last != null && last.artist.trim().toLowerCase() == artist) {
        score += 4.0;
      }
    }

    if (album.isNotEmpty) {
      final albumSignals = _signals.values.where(
        (item) => item.album.trim().toLowerCase() == album,
      );
      score += albumSignals.fold<double>(
        0.0,
        (total, item) => total + item.playCount * 0.75,
      );
    }

    if (title.isNotEmpty && signal != null) {
      score -= signal.skipCount * 3.0;
    }

    return score;
  }

  /// Returns candidates ordered by current-session preference.
  List<OnlineSong> rankOnlineSongs(Iterable<OnlineSong> songs) {
    final ranked = songs.map((song) {
      return _ScoredOnlineSong(
        song: song,
        score: scoreOnlineSong(song),
      );
    }).toList();

    ranked.sort((a, b) {
      final score = b.score.compareTo(a.score);
      if (score != 0) return score;
      return a.song.title.toLowerCase().compareTo(
            b.song.title.toLowerCase(),
          );
    });

    return ranked.map((item) => item.song).toList(growable: false);
  }
}

class SessionTrackSignal {
  const SessionTrackSignal({
    required this.song,
    required this.playCount,
    required this.skipCount,
    required this.completionCount,
    required this.completionRatio,
    required this.lastPosition,
    required this.duration,
    required this.lastPlayed,
    this.lastSkipped,
  });

  factory SessionTrackSignal.fromSong(Song song) {
    return SessionTrackSignal(
      song: song,
      playCount: 0,
      skipCount: 0,
      completionCount: 0,
      completionRatio: 0.0,
      lastPosition: Duration.zero,
      duration: song.duration,
      lastPlayed: DateTime.now(),
    );
  }

  final Song song;
  final int playCount;
  final int skipCount;
  final int completionCount;
  final double completionRatio;
  final Duration lastPosition;
  final Duration duration;
  final DateTime lastPlayed;
  final DateTime? lastSkipped;

  String get artist => song.artist;
  String get album => song.album;

  SessionTrackSignal copyWith({
    Song? song,
    int? playCount,
    int? skipCount,
    int? completionCount,
    double? completionRatio,
    Duration? lastPosition,
    Duration? duration,
    DateTime? lastPlayed,
    DateTime? lastSkipped,
  }) {
    return SessionTrackSignal(
      song: song ?? this.song,
      playCount: playCount ?? this.playCount,
      skipCount: skipCount ?? this.skipCount,
      completionCount: completionCount ?? this.completionCount,
      completionRatio: completionRatio ?? this.completionRatio,
      lastPosition: lastPosition ?? this.lastPosition,
      duration: duration ?? this.duration,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      lastSkipped: lastSkipped ?? this.lastSkipped,
    );
  }
}

class _ScoredOnlineSong {
  const _ScoredOnlineSong({
    required this.song,
    required this.score,
  });

  final OnlineSong song;
  final double score;
}
