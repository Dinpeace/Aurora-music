import '../models/listening_history_entry.dart';
import '../models/online/online_song.dart';
import 'mood_energy_service.dart';
import 'session_pattern_recognition_service.dart';
import 'smart_queue_service.dart';
import 'taste_profile_service.dart';

/// Applies recognized session patterns as a bounded ranking layer.
///
/// The pattern strategy never mutates persistent taste/history and never
/// bypasses SmartQueueService's normal adaptive/context ranking.
class PatternAwareQueueStrategyService {
  PatternAwareQueueStrategyService({
    required SessionPatternRecognitionService recognizer,
  }) : _recognizer = recognizer;

  final SessionPatternRecognitionService _recognizer;

  List<String> get patterns => _recognizer.patterns;

  List<OnlineSong> rank({
    required Iterable<OnlineSong> ranked,
    int limit = 12,
  }) {
    if (limit <= 0) return const <OnlineSong>[];

    final songs = ranked.toList(growable: false);
    if (songs.length <= 1 || patterns.isEmpty) {
      return songs.take(limit).toList(growable: false);
    }

    final scored = <_PatternCandidate>[];

    for (var index = 0; index < songs.length; index++) {
      final song = songs[index];
      var score = (songs.length - index) * 0.01;

      if (_recognizer.hasPattern('repeated_skip_discovery')) {
        score += _discoveryBonus(song);
      }

      if (_recognizer.hasPattern('artist_affinity')) {
        score += _affinityBonus(song);
      }

      if (_recognizer.hasPattern('completion_heavy')) {
        score += _continuationBonus(song);
      }

      if (_recognizer.hasPattern('alternating_balanced')) {
        score += _balancedBonus(song);
      }

      scored.add(_PatternCandidate(song, score));
    }

    scored.sort((a, b) {
      final comparison = b.score.compareTo(a.score);
      if (comparison != 0) return comparison;
      return a.song.title.toLowerCase().compareTo(
            b.song.title.toLowerCase(),
          );
    });

    return scored
        .take(limit)
        .map((candidate) => candidate.song)
        .toList(growable: false);
  }

  double _discoveryBonus(OnlineSong song) {
    final title = '${song.title} ${song.album}'.toLowerCase();
    // The recognizer says the session is rejecting familiarity. Favor signals
    // that look less like a continuation of an established favorite.
    if (title.contains('live') || title.contains('remix')) return 1.5;
    return 1.0;
  }

  double _affinityBonus(OnlineSong song) {
    final artist = song.artist.trim().toLowerCase();
    if (artist.isEmpty) return 0.0;
    return 1.0;
  }

  double _continuationBonus(OnlineSong song) {
    final title = '${song.title} ${song.album}'.toLowerCase();
    if (title.contains('part') ||
        title.contains('version') ||
        title.contains('acoustic')) {
      return 0.8;
    }
    return 0.35;
  }

  double _balancedBonus(OnlineSong song) {
    final title = '${song.title} ${song.album}'.toLowerCase();
    if (title.contains('remix') || title.contains('live')) return 0.15;
    return 0.35;
  }
}

extension PatternAwareQueueBuild on SmartQueueService {
  List<OnlineSong> buildWithPatternStrategy({
    required Iterable<OnlineSong> candidates,
    required TasteProfile profile,
    required List<ListeningHistoryEntry> history,
    required SessionPatternRecognitionService recognizer,
    MoodProfile? mood,
    Iterable<OnlineSong> currentQueue = const <OnlineSong>[],
    int length = 12,
  }) {
    final base = build(
      candidates: candidates,
      profile: profile,
      history: history,
      currentQueue: currentQueue,
      mood: mood,
      mode: ListeningMode.balanced,
      length: length * 2,
    );

    return PatternAwareQueueStrategyService(
      recognizer: recognizer,
    ).rank(
      ranked: base,
      limit: length,
    );
  }
}

class _PatternCandidate {
  const _PatternCandidate(this.song, this.score);

  final OnlineSong song;
  final double score;
}
