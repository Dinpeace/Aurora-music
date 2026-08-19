import '../models/listening_history_entry.dart';
import '../models/online/online_song.dart';
import 'mood_energy_service.dart';
import 'session_intelligence_service.dart';
import 'smart_queue_service.dart';
import 'taste_profile_service.dart';

/// Converts short-lived session signals into a temporary listening mode.
///
/// This service never mutates TasteProfile or persistent listening history.
/// The mode changes only when session evidence crosses a confidence threshold,
/// which prevents a single skip/play from causing abrupt mode changes.
class AdaptiveSessionModeService {
  AdaptiveSessionModeService({
    required SessionIntelligenceService session,
    this.minimumEvents = 3,
    this.switchThreshold = 0.60,
  }) : _session = session;

  final SessionIntelligenceService _session;
  final int minimumEvents;
  final double switchThreshold;

  ListeningMode _current = ListeningMode.balanced;

  ListeningMode get currentMode => _current;

  void reset() {
    _current = ListeningMode.balanced;
  }

  ListeningMode inferMode() {
    final total = _session.playedCount + _session.skippedCount;
    if (total < minimumEvents) return _current;

    final skips = _session.skippedCount;
    final plays = _session.playedCount;
    final artistCounts = _session.artistPlayCounts;

    final dominantArtistPlays = artistCounts.values.isEmpty
        ? 0
        : artistCounts.values.reduce((a, b) => a > b ? a : b);

    final skipRate = plays == 0 ? 0.0 : skips / plays;
    final repeatRate = plays == 0 ? 0.0 : dominantArtistPlays / plays;

    ListeningMode candidate = ListeningMode.balanced;

    // Strong rejection signals: move toward discovery.
    if (skipRate >= 0.60) {
      candidate = ListeningMode.discovery;
    } else if (repeatRate >= 0.70 && skipRate <= 0.20) {
      candidate = ListeningMode.favorites;
    } else if (plays >= 4 && skipRate <= 0.15) {
      // A stable, low-skip session is better treated as balanced than
      // permanently changing the user's taste.
      candidate = ListeningMode.balanced;
    }

    // Only switch when the candidate is sufficiently different and the
    // session has enough evidence. This is deliberate hysteresis.
    if (candidate == _current) return _current;

    final confidence = _confidence(
      candidate: candidate,
      skipRate: skipRate,
      repeatRate: repeatRate,
    );

    if (confidence >= switchThreshold) {
      _current = candidate;
    }

    return _current;
  }

  double _confidence({
    required ListeningMode candidate,
    required double skipRate,
    required double repeatRate,
  }) {
    switch (candidate) {
      case ListeningMode.discovery:
        return skipRate;
      case ListeningMode.favorites:
        return repeatRate;
      case ListeningMode.balanced:
        return 1.0 - (skipRate * 0.5);
      case ListeningMode.focus:
      case ListeningMode.chill:
        return 0.0;
    }
  }
}

/// Convenience entry point for using automatically inferred session context
/// without changing the existing SmartQueueService API.
extension SmartQueueSessionAutoMode on SmartQueueService {
  List<OnlineSong> buildWithSessionMode({
    required Iterable<OnlineSong> candidates,
    required TasteProfile profile,
    required List<ListeningHistoryEntry> history,
    required AdaptiveSessionModeService sessionMode,
    Iterable<OnlineSong> currentQueue = const <OnlineSong>[],
    MoodProfile? mood,
    int length = 12,
  }) {
    return build(
      candidates: candidates,
      profile: profile,
      history: history,
      currentQueue: currentQueue,
      mood: mood,
      mode: sessionMode.inferMode(),
      length: length,
    );
  }
}
