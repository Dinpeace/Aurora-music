import '../models/listening_history_entry.dart';
import '../models/online/online_song.dart';
import 'mood_energy_service.dart';
import 'session_intelligence_service.dart';
import 'smart_queue_service.dart';
import 'taste_profile_service.dart';

/// Evolves the temporary session mode gradually.
///
/// Persistent taste is never modified. Evidence is accumulated only inside
/// this service and the existing SessionIntelligenceService.
class SessionAwareQueueEvolutionService {
  SessionAwareQueueEvolutionService({
    required SessionIntelligenceService session,
    this.minimumEvents = 3,
    this.switchThreshold = 0.60,
    this.smoothing = 0.35,
  }) : _session = session;

  final SessionIntelligenceService _session;
  final int minimumEvents;
  final double switchThreshold;
  final double smoothing;

  ListeningMode _mode = ListeningMode.balanced;
  double _confidence = 0.0;

  ListeningMode get mode => _mode;
  double get confidence => _confidence;

  void reset() {
    _mode = ListeningMode.balanced;
    _confidence = 0.0;
  }

  ListeningMode update() {
    final total = _session.playedCount + _session.skippedCount;
    if (total < minimumEvents) return _mode;

    final plays = _session.playedCount;
    final skips = _session.skippedCount;
    final skipRate = plays == 0 ? 0.0 : skips / plays;

    final artistCounts = _session.artistPlayCounts;
    final dominant = artistCounts.values.isEmpty
        ? 0
        : artistCounts.values.reduce((a, b) => a > b ? a : b);
    final repeatRate = plays == 0 ? 0.0 : dominant / plays;

    final candidate = _candidate(skipRate, repeatRate);
    final rawConfidence = _candidateConfidence(
      candidate,
      skipRate,
      repeatRate,
    );

    _confidence = _confidence == 0.0
        ? rawConfidence
        : (_confidence * (1.0 - smoothing)) +
            (rawConfidence * smoothing);

    if (candidate == _mode) return _mode;

    // Strong evidence can switch immediately; moderate evidence must build
    // over multiple updates. This creates gradual session evolution.
    if (rawConfidence >= switchThreshold ||
        _confidence >= switchThreshold) {
      _mode = candidate;
    }

    return _mode;
  }

  ListeningMode _candidate(double skipRate, double repeatRate) {
    if (skipRate >= 0.60) return ListeningMode.discovery;
    if (repeatRate >= 0.70 && skipRate <= 0.20) {
      return ListeningMode.favorites;
    }
    return ListeningMode.balanced;
  }

  double _candidateConfidence(
    ListeningMode candidate,
    double skipRate,
    double repeatRate,
  ) {
    switch (candidate) {
      case ListeningMode.discovery:
        return skipRate.clamp(0.0, 1.0);
      case ListeningMode.favorites:
        return repeatRate.clamp(0.0, 1.0);
      case ListeningMode.balanced:
        return (1.0 - (skipRate * 0.5)).clamp(0.0, 1.0);
      case ListeningMode.focus:
      case ListeningMode.chill:
        return 0.0;
    }
  }

  List<OnlineSong> buildQueue({
    required SmartQueueService queue,
    required Iterable<OnlineSong> candidates,
    required TasteProfile profile,
    required List<ListeningHistoryEntry> history,
    Iterable<OnlineSong> currentQueue = const <OnlineSong>[],
    MoodProfile? mood,
    int length = 12,
  }) {
    final activeMode = update();

    return queue.build(
      candidates: candidates,
      profile: profile,
      history: history,
      currentQueue: currentQueue,
      mood: mood,
      mode: activeMode,
      length: length,
    );
  }
}
