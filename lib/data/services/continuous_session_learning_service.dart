import '../models/listening_history_entry.dart';
import '../models/online/online_song.dart';
import 'mood_energy_service.dart';
import 'taste_profile_service.dart';
import 'predictive_queue_intent_service.dart';
import 'session_intelligence_service.dart';
import 'smart_queue_service.dart';

/// Continuously learns the direction of the current session.
///
/// Unlike a one-shot mode switch, this keeps a short trajectory score and
/// updates it whenever new session evidence is observed. It is intentionally
/// ephemeral and does not write to persistent taste/history.
class ContinuousSessionLearningService {
  ContinuousSessionLearningService({
    required SessionIntelligenceService session,
    required PredictiveQueueIntentService predictor,
    this.learningRate = 0.30,
    this.minimumConfidence = 0.45,
  })  : _session = session,
        _predictor = predictor;

  final SessionIntelligenceService _session;
  final PredictiveQueueIntentService _predictor;
  final double learningRate;
  final double minimumConfidence;

  double _discoverySignal = 0.0;
  double _favoritesSignal = 0.0;
  int _lastPlayedCount = 0;
  int _lastSkippedCount = 0;

  double get discoverySignal => _discoverySignal;
  double get favoritesSignal => _favoritesSignal;

  ListeningMode get direction {
    if (_discoverySignal >= _favoritesSignal &&
        _discoverySignal >= minimumConfidence) {
      return ListeningMode.discovery;
    }
    if (_favoritesSignal > _discoverySignal &&
        _favoritesSignal >= minimumConfidence) {
      return ListeningMode.favorites;
    }
    return ListeningMode.balanced;
  }

  void reset() {
    _discoverySignal = 0.0;
    _favoritesSignal = 0.0;
    _lastPlayedCount = 0;
    _lastSkippedCount = 0;
  }

  ListeningMode learn() {
    final plays = _session.playedCount;
    final skips = _session.skippedCount;

    final newPlays = (plays - _lastPlayedCount).clamp(0, plays);
    final newSkips = (skips - _lastSkippedCount).clamp(0, skips);

    _lastPlayedCount = plays;
    _lastSkippedCount = skips;

    if (newPlays == 0 && newSkips == 0) {
      _predictor.predict();
      return direction;
    }

    final rejection = plays == 0 ? 0.0 : skips / plays;
    final repetition = _dominantArtistShare(plays);

    final discoveryEvidence =
        (rejection * 0.75 + (newSkips > 0 ? 0.25 : 0.0)).clamp(0.0, 1.0);
    final favoriteEvidence =
        (repetition * 0.75 + (newSkips == 0 && newPlays > 0 ? 0.25 : 0.0))
            .clamp(0.0, 1.0);

    _discoverySignal = _blend(_discoverySignal, discoveryEvidence);
    _favoritesSignal = _blend(_favoritesSignal, favoriteEvidence);

    // The predictor remains the forward-looking signal; continuous learning
    // complements it rather than replacing it.
    _predictor.predict();

    return direction;
  }

  double _blend(double previous, double evidence) {
    return previous * (1.0 - learningRate) + evidence * learningRate;
  }

  double _dominantArtistShare(int plays) {
    if (plays <= 0 || _session.artistPlayCounts.isEmpty) return 0.0;
    final dominant =
        _session.artistPlayCounts.values.reduce((a, b) => a > b ? a : b);
    return (dominant / plays).clamp(0.0, 1.0);
  }
}

extension ContinuousSmartQueueLearning on SmartQueueService {
  List<OnlineSong> buildWithContinuousLearning({
    required Iterable<OnlineSong> candidates,
    required TasteProfile profile,
    required List<ListeningHistoryEntry> history,
    required ContinuousSessionLearningService learner,
    Iterable<OnlineSong> currentQueue = const <OnlineSong>[],
    MoodProfile? mood,
    int length = 12,
  }) {
    final mode = learner.learn();

    return build(
      candidates: candidates,
      profile: profile,
      history: history,
      currentQueue: currentQueue,
      mood: mood,
      mode: mode,
      length: length,
    );
  }
}
