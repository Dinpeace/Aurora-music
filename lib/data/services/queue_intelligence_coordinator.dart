import 'continuous_session_learning_service.dart';
import 'predictive_queue_intent_service.dart';
import 'session_pattern_recognition_service.dart';
import 'session_intelligence_service.dart';
import 'smart_queue_service.dart';

/// The single decision layer for Smart Queue intelligence.
///
/// v19 deliberately does not replace the existing intelligence services.
/// It coordinates their outputs into one normalized, deterministic decision.
class QueueIntelligenceCoordinator {
  QueueIntelligenceCoordinator({
    required SessionIntelligenceService session,
    required PredictiveQueueIntentService predictor,
    required ContinuousSessionLearningService learner,
    required SessionPatternRecognitionService patterns,
  })  : _session = session,
        _predictor = predictor,
        _learner = learner,
        _patterns = patterns;

  final SessionIntelligenceService _session;
  final PredictiveQueueIntentService _predictor;
  final ContinuousSessionLearningService _learner;
  final SessionPatternRecognitionService _patterns;

  QueueIntelligenceDecision _lastDecision =
      const QueueIntelligenceDecision.balanced();

  QueueIntelligenceDecision get lastDecision => _lastDecision;

  QueueIntelligenceDecision evaluate() {
    final predicted = _predictor.predict();
    final learned = _learner.learn();
    final recognized = _patterns.observe();

    final discoverySignal = _clamp(
      _weighted(
        _predictor.confidence,
        _learner.discoverySignal,
        recognized.contains('repeated_skip_discovery') ? 1.0 : 0.0,
      ),
    );

    final favoriteSignal = _clamp(
      _weighted(
        predicted == ListeningMode.favorites ? _predictor.confidence : 0.0,
        _learner.favoritesSignal,
        recognized.contains('artist_affinity') ? 1.0 : 0.0,
      ),
    );

    final mode = _resolveMode(
      predicted: predicted,
      learned: learned,
      patterns: recognized,
      discoverySignal: discoverySignal,
      favoriteSignal: favoriteSignal,
    );

    final confidence = _resolveConfidence(
      mode: mode,
      discoverySignal: discoverySignal,
      favoriteSignal: favoriteSignal,
    );

    _lastDecision = QueueIntelligenceDecision(
      mode: mode,
      confidence: confidence,
      discoverySignal: discoverySignal,
      familiaritySignal: favoriteSignal,
      patterns: recognized,
      playedCount: _session.playedCount,
      skippedCount: _session.skippedCount,
    );

    return _lastDecision;
  }

  void reset() {
    _predictor.reset();
    _learner.reset();
    _patterns.reset();
    _lastDecision = const QueueIntelligenceDecision.balanced();
  }

  double _weighted(double prediction, double learning, double pattern) {
    // Prediction is forward-looking, learning is trajectory-based, and the
    // recognized pattern is a strong but bounded confirmation signal.
    return (prediction * 0.35) + (learning * 0.40) + (pattern * 0.25);
  }

  ListeningMode _resolveMode({
    required ListeningMode predicted,
    required ListeningMode learned,
    required List<String> patterns,
    required double discoverySignal,
    required double favoriteSignal,
  }) {
    final hasDiscoveryPattern =
        patterns.contains('repeated_skip_discovery');
    final hasFavoritePattern = patterns.contains('artist_affinity');

    // Strong current-session rejection wins over familiarity. This prevents
    // a long-term favorite from dominating while the user is clearly
    // skipping similar material.
    if (hasDiscoveryPattern || discoverySignal >= 0.55) {
      return ListeningMode.discovery;
    }

    if (hasFavoritePattern || favoriteSignal >= 0.55) {
      return ListeningMode.favorites;
    }

    if (predicted == ListeningMode.discovery ||
        learned == ListeningMode.discovery) {
      return discoverySignal >= 0.45
          ? ListeningMode.discovery
          : ListeningMode.balanced;
    }

    if (predicted == ListeningMode.favorites ||
        learned == ListeningMode.favorites) {
      return favoriteSignal >= 0.45
          ? ListeningMode.favorites
          : ListeningMode.balanced;
    }

    return ListeningMode.balanced;
  }

  double _resolveConfidence({
    required ListeningMode mode,
    required double discoverySignal,
    required double favoriteSignal,
  }) {
    switch (mode) {
      case ListeningMode.discovery:
        return discoverySignal;
      case ListeningMode.favorites:
        return favoriteSignal;
      case ListeningMode.balanced:
      case ListeningMode.focus:
      case ListeningMode.chill:
        // Balanced with no evidence is intentionally low-confidence.
        // Confidence should rise only when the fused signals contain
        // meaningful session evidence.
        if (discoverySignal == 0.0 && favoriteSignal == 0.0) {
          return 0.0;
        }
        return 1.0 - (discoverySignal - favoriteSignal).abs();
    }
  }

  double _clamp(double value) => value.clamp(0.0, 1.0);
}

/// Immutable, testable output from the intelligence fusion layer.
class QueueIntelligenceDecision {
  const QueueIntelligenceDecision({
    required this.mode,
    required this.confidence,
    required this.discoverySignal,
    required this.familiaritySignal,
    required this.patterns,
    required this.playedCount,
    required this.skippedCount,
  });

  const QueueIntelligenceDecision.balanced()
      : mode = ListeningMode.balanced,
        confidence = 0.0,
        discoverySignal = 0.0,
        familiaritySignal = 0.0,
        patterns = const <String>[],
        playedCount = 0,
        skippedCount = 0;

  final ListeningMode mode;
  final double confidence;
  final double discoverySignal;
  final double familiaritySignal;
  final List<String> patterns;
  final int playedCount;
  final int skippedCount;

  bool get isConfident => confidence >= 0.55;

  @override
  String toString() =>
      'QueueIntelligenceDecision(mode: $mode, confidence: '
      '${confidence.toStringAsFixed(3)}, discovery: '
      '${discoverySignal.toStringAsFixed(3)}, familiarity: '
      '${familiaritySignal.toStringAsFixed(3)}, patterns: $patterns)';
}
