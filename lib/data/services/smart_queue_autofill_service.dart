import '../models/online/online_song.dart';
import 'mood_energy_service.dart';
import 'smart_queue_service.dart';
import 'taste_profile_service.dart';

/// Keeps a playback queue supplied with recommendation-driven continuation.
///
/// The player remains the owner of playback state. This coordinator only
/// decides when more tracks are needed and returns the updated queue.
class SmartQueueAutofillService {
  SmartQueueAutofillService({
    required SmartQueueService smartQueue,
    required MoodEnergyService mood,
  })  : _smartQueue = smartQueue,
        _mood = mood;

  final SmartQueueService _smartQueue;
  final MoodEnergyService _mood;

  bool shouldAutofill({
    required int currentIndex,
    required int queueLength,
    int threshold = 2,
  }) {
    if (queueLength <= 0 || currentIndex < 0) return false;
    if (currentIndex >= queueLength) return true;

    final remaining = queueLength - currentIndex - 1;
    return remaining <= threshold;
  }

  List<OnlineSong> autofill({
    required Iterable<OnlineSong> candidates,
    required Iterable<OnlineSong> currentQueue,
    required int currentIndex,
    required TasteProfile profile,
    MoodProfile? mood,
    int threshold = 2,
    int additional = 5,
  }) {
    final queue = currentQueue.toList(growable: false);

    if (!shouldAutofill(
      currentIndex: currentIndex,
      queueLength: queue.length,
      threshold: threshold,
    )) {
      return List<OnlineSong>.unmodifiable(queue);
    }

    final selectedMood = mood ?? _mood.inferCurrentProfile();

    return _smartQueue.append(
      candidates: candidates,
      currentQueue: queue,
      profile: profile,
      mood: selectedMood,
      additional: additional,
    );
  }

  List<OnlineSong> fillToMinimum({
    required Iterable<OnlineSong> candidates,
    required Iterable<OnlineSong> currentQueue,
    required TasteProfile profile,
    MoodProfile? mood,
    int minimumLength = 8,
    int batchSize = 5,
  }) {
    var queue = currentQueue.toList(growable: false);

    if (queue.length >= minimumLength) {
      return List<OnlineSong>.unmodifiable(queue);
    }

    final selectedMood = mood ?? _mood.inferCurrentProfile();
    final needed = minimumLength - queue.length;
    final additions = needed > batchSize ? batchSize : needed;

    queue = _smartQueue.append(
      candidates: candidates,
      currentQueue: queue,
      profile: profile,
      mood: selectedMood,
      additional: additions,
    );

    return List<OnlineSong>.unmodifiable(queue);
  }
}
