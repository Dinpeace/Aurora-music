import '../models/listening_history_entry.dart';
import '../models/online/online_song.dart';
import 'mood_energy_service.dart';
import 'predictive_queue_intent_service.dart';
import 'smart_queue_service.dart';
import 'taste_profile_service.dart';

/// Regenerates only the unplayed tail of a queue when predictive intent
/// changes materially. The currently playing item and consumed history remain
/// untouched.
class PredictiveQueueRegenerationService {
  PredictiveQueueRegenerationService({
    required PredictiveQueueIntentService predictor,
    required SmartQueueService queue,
    this.minimumConfidence = 0.55,
  })  : _predictor = predictor,
        _queue = queue;

  final PredictiveQueueIntentService _predictor;
  final SmartQueueService _queue;
  final double minimumConfidence;

  ListeningMode? _lastAppliedMode;

  ListeningMode? get lastAppliedMode => _lastAppliedMode;

  void reset() {
    _lastAppliedMode = null;
  }

  bool get shouldRegenerate {
    final predicted = _predictor.predict();
    final confidence = _predictor.confidence;

    return confidence >= minimumConfidence &&
        predicted != _lastAppliedMode;
  }

  List<OnlineSong> regenerateTail({
    required Iterable<OnlineSong> candidates,
    required Iterable<OnlineSong> currentQueue,
    required TasteProfile profile,
    required List<ListeningHistoryEntry> history,
    Iterable<OnlineSong> protectedItems = const <OnlineSong>[],
    MoodProfile? mood,
    int tailLength = 6,
  }) {
    if (tailLength <= 0) {
      return List<OnlineSong>.unmodifiable(currentQueue);
    }

    final predicted = _predictor.predict();
    if (_predictor.confidence < minimumConfidence) {
      return List<OnlineSong>.unmodifiable(currentQueue);
    }

    final existing = currentQueue.toList(growable: false);
    final protectedIds = protectedItems
        .map((song) => song.id.trim().toLowerCase())
        .where((id) => id.isNotEmpty)
        .toSet();

    final retained = existing
        .where((song) => protectedIds.contains(song.id.trim().toLowerCase()))
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

    _lastAppliedMode = predicted;

    return List<OnlineSong>.unmodifiable([
      ...retained,
      ...generated,
    ]);
  }
}
