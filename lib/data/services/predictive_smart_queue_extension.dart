import '../models/listening_history_entry.dart';
import '../models/online/online_song.dart';
import 'mood_energy_service.dart';
import 'predictive_queue_intent_service.dart';
import 'smart_queue_service.dart';
import 'taste_profile_service.dart';

extension PredictiveSmartQueue on SmartQueueService {
  List<OnlineSong> buildWithPredictedIntent({
    required Iterable<OnlineSong> candidates,
    required TasteProfile profile,
    required List<ListeningHistoryEntry> history,
    required PredictiveQueueIntentService predictor,
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
      mode: predictor.predict(),
      length: length,
    );
  }
}
