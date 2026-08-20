import '../models/listening_history_entry.dart';
import '../models/online/online_song.dart';
import 'mood_energy_service.dart';
import 'taste_profile_service.dart';
import 'continuous_session_learning_service.dart';
import 'session_intelligence_service.dart';
import 'smart_queue_service.dart';

/// Recognizes recurring short-term session patterns without persisting them.
class SessionPatternRecognitionService {
  SessionPatternRecognitionService({
    required SessionIntelligenceService session,
    required ContinuousSessionLearningService learner,
    this.windowSize = 5,
  })  : _session = session,
        _learner = learner;

  final SessionIntelligenceService _session;
  final ContinuousSessionLearningService _learner;
  final int windowSize;

  final List<_PatternSample> _samples = <_PatternSample>[];

  List<String> get patterns =>
      List<String>.unmodifiable(_recognizedPatterns());

  void reset() {
    _samples.clear();
  }

  List<String> observe() {
    _learner.learn();

    final sample = _PatternSample(
      plays: _session.playedCount,
      skips: _session.skippedCount,
      discovery: _learner.discoverySignal,
      favorites: _learner.favoritesSignal,
    );

    if (_samples.isEmpty ||
        _samples.last.plays != sample.plays ||
        _samples.last.skips != sample.skips) {
      _samples.add(sample);
      if (_samples.length > windowSize) {
        _samples.removeAt(0);
      }
    }

    return patterns;
  }

  bool hasPattern(String pattern) => patterns.contains(pattern);

  List<String> _recognizedPatterns() {
    if (_samples.isEmpty) return const <String>[];

    final latest = _samples.last;
    final result = <String>[];

    final recentSkips = _samples.where(
      (sample) => sample.skips > 0,
    ).length;

    if (recentSkips >= 2 && latest.discovery >= 0.45) {
      result.add('repeated_skip_discovery');
    }

    if (latest.favorites >= 0.45) {
      result.add('artist_affinity');
    }

    if (latest.plays >= 3) {
      final completionSignal =
          _session.artistPlayCounts.values.fold<int>(0, (a, b) => a + b);
      if (completionSignal >= 3 && _session.skippedCount == 0) {
        result.add('completion_heavy');
      }
    }

    if (_samples.length >= 3) {
      final hasSkips = _samples.any((sample) => sample.skips > 0);
      final hasPlayGrowth = _samples.last.plays > _samples.first.plays;
      if (hasSkips && hasPlayGrowth && latest.discovery < 0.65) {
        result.add('alternating_balanced');
      }
    }

    return result;
  }
}

class _PatternSample {
  const _PatternSample({
    required this.plays,
    required this.skips,
    required this.discovery,
    required this.favorites,
  });

  final int plays;
  final int skips;
  final double discovery;
  final double favorites;
}

extension PatternAwareSmartQueue on SmartQueueService {
  List<OnlineSong> buildWithSessionPatterns({
    required Iterable<OnlineSong> candidates,
    required TasteProfile profile,
    required List<ListeningHistoryEntry> history,
    required SessionPatternRecognitionService recognizer,
    Iterable<OnlineSong> currentQueue = const <OnlineSong>[],
    MoodProfile? mood,
    int length = 12,
  }) {
    recognizer.observe();

    return build(
      candidates: candidates,
      profile: profile,
      history: history,
      currentQueue: currentQueue,
      mood: mood,
      mode: recognizer.hasPattern('repeated_skip_discovery')
          ? ListeningMode.discovery
          : recognizer.hasPattern('artist_affinity')
              ? ListeningMode.favorites
              : ListeningMode.balanced,
      length: length,
    );
  }
}
