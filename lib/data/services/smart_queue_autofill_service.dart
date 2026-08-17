import '../models/listening_history_entry.dart';
import '../models/online/online_song.dart';
import 'mood_energy_service.dart';
import 'smart_queue_service.dart';
import 'taste_profile_service.dart';

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
    return queueLength - currentIndex - 1 <= threshold;
  }

  List<OnlineSong> autofill({
    required Iterable<OnlineSong> candidates,
    required Iterable<OnlineSong> currentQueue,
    required int currentIndex,
    required TasteProfile profile,
    required List<ListeningHistoryEntry> history,
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

    mood ??= _mood.inferCurrentProfile();

    return _smartQueue.append(
      candidates: candidates,
      currentQueue: queue,
      profile: profile,
      history: history,
      mood: mood,
      additional: additional,
    );
  }

  List<OnlineSong> fillToMinimum({
    required Iterable<OnlineSong> candidates,
    required Iterable<OnlineSong> currentQueue,
    required TasteProfile profile,
    required List<ListeningHistoryEntry> history,
    MoodProfile? mood,
    int minimumLength = 8,
    int batchSize = 5,
  }) {
    final queue = currentQueue.toList(growable: false);
    if (queue.length >= minimumLength) {
      return List<OnlineSong>.unmodifiable(queue);
    }

    mood ??= _mood.inferCurrentProfile();

    final needed = minimumLength - queue.length;
    final additions = needed > batchSize ? batchSize : needed;

    return _smartQueue.append(
      candidates: candidates,
      currentQueue: queue,
      profile: profile,
      history: history,
      mood: mood,
      additional: additions,
    );
  }
}
