import 'session_intelligence_service.dart';
import 'smart_queue_service.dart';

class PredictiveQueueIntentService {
  PredictiveQueueIntentService({
    required SessionIntelligenceService session,
    this.minimumEvents = 4,
    this.smoothing = 0.30,
  }) : _session = session;

  final SessionIntelligenceService _session;
  final int minimumEvents;
  final double smoothing;

  ListeningMode _predicted = ListeningMode.balanced;
  double _confidence = 0.0;

  ListeningMode get predictedMode => _predicted;
  double get confidence => _confidence;

  void reset() {
    _predicted = ListeningMode.balanced;
    _confidence = 0.0;
  }

  ListeningMode predict() {
    final plays = _session.playedCount;
    final skips = _session.skippedCount;
    if (plays + skips < minimumEvents) return _predicted;

    final skipRate = plays == 0 ? 0.0 : skips / plays;
    final repeatRate = _dominantArtistShare(plays);
    final trajectory = (repeatRate - skipRate).clamp(-1.0, 1.0);

    final candidate = skipRate >= 0.45 || trajectory <= -0.35
        ? ListeningMode.discovery
        : (repeatRate >= 0.60 && trajectory >= 0.10
            ? ListeningMode.favorites
            : ListeningMode.balanced);

    final raw = candidate == ListeningMode.discovery
        ? ((skipRate * 0.65) + ((-trajectory).clamp(0.0, 1.0) * 0.35))
        : candidate == ListeningMode.favorites
            ? ((repeatRate * 0.65) + (trajectory.clamp(0.0, 1.0) * 0.35))
            : (1.0 - skipRate * 0.5);

    // Discovery needs to react slightly earlier than the v12 hard session
    // threshold; prediction is intentionally anticipatory.
    final rawConfidence = raw.clamp(0.0, 1.0);
    _confidence = _confidence == 0.0
        ? rawConfidence
        : _confidence * (1.0 - smoothing) + rawConfidence * smoothing;

    // Keep predictive confidence representative of the current trajectory.
    // Once a clear Discovery trajectory is detected, don't let smoothing
    // hide that signal behind an older low-confidence state.
    if (candidate == ListeningMode.discovery) {
      _confidence = rawConfidence.clamp(0.55, 1.0);
    }

    if (candidate != _predicted && _confidence >= 0.45) {
      _predicted = candidate;
    }
    return _predicted;
  }

  double _dominantArtistShare(int plays) {
    if (plays <= 0 || _session.artistPlayCounts.isEmpty) return 0.0;
    final dominant =
        _session.artistPlayCounts.values.reduce((a, b) => a > b ? a : b);
    return (dominant / plays).clamp(0.0, 1.0);
  }
}
