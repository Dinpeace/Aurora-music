import '../models/listening_history_entry.dart';
import '../models/online/online_song.dart';
import 'mood_energy_service.dart';
import 'predictive_queue_intent_service.dart';
import 'smart_queue_service.dart';
import 'taste_profile_service.dart';

/// Coordinates live queue-tail adaptation while protecting the currently
/// playing item and suppressing redundant regenerations.
class RealtimeQueueAdaptationService {
  RealtimeQueueAdaptationService({
    required PredictiveQueueIntentService predictor,
    required SmartQueueService queue,
    this.minimumConfidence = 0.55,
    this.minimumModeChange = true,
  })  : _predictor = predictor,
        _queue = queue;

  final PredictiveQueueIntentService _predictor;
  final SmartQueueService _queue;
  final double minimumConfidence;
  final bool minimumModeChange;

  ListeningMode? _appliedMode;
  int _generation = 0;

  ListeningMode? get appliedMode => _appliedMode;
  int get generation => _generation;

  void reset() {
    _appliedMode = null;
    _generation = 0;
  }

  bool shouldAdapt() {
    final predicted = _predictor.predict();
    if (_predictor.confidence < minimumConfidence) return false;
    if (!minimumModeChange) return true;
    return predicted != _appliedMode;
  }

  List<OnlineSong> adaptTail({
    required Iterable<OnlineSong> candidates,
    required Iterable<OnlineSong> currentQueue,
    required Iterable<OnlineSong> protectedItems,
    required TasteProfile profile,
    required List<ListeningHistoryEntry> history,
    MoodProfile? mood,
    int tailLength = 6,
  }) {
    final predicted = _predictor.predict();
    if (_predictor.confidence < minimumConfidence) {
      return List<OnlineSong>.unmodifiable(currentQueue);
    }

    if (minimumModeChange && predicted == _appliedMode) {
      return List<OnlineSong>.unmodifiable(currentQueue);
    }

    final existing = currentQueue.toList(growable: false);
    final protectedIds = protectedItems
        .map(_normalizeId)
        .where((id) => id.isNotEmpty)
        .toSet();

    // Everything protected is retained in its original order. The remaining
    // tail is rebuilt against the new predicted mode.
    final retained = existing
        .where((song) => protectedIds.contains(_normalizeId(song)))
        .toList(growable: false);

    final generated = _queue.build(
      candidates: candidates,
      profile: profile,
      history: history,
      currentQueue: retained,
      mood: mood,
      mode: predicted,
      length: tailLength,
    );

    _appliedMode = predicted;
    _generation++;

    return List<OnlineSong>.unmodifiable([
      ...retained,
      ...generated,
    ]);
  }

  String _normalizeId(OnlineSong song) => song.id.trim().toLowerCase();
}
