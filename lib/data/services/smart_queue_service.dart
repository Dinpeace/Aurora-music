import '../models/listening_history_entry.dart';
import '../models/online/online_song.dart';
import 'adaptive_recommendation_service.dart';
import 'mood_energy_service.dart';
import 'taste_profile_service.dart';

class SmartQueueService {
  SmartQueueService({
    required AdaptiveRecommendationService adaptive,
    required MoodEnergyService mood,
  })  : _adaptive = adaptive,
        _mood = mood;

  final AdaptiveRecommendationService _adaptive;
  final MoodEnergyService _mood;

  List<OnlineSong> build({
    required Iterable<OnlineSong> candidates,
    required TasteProfile profile,
    required List<ListeningHistoryEntry> history,
    Iterable<OnlineSong> currentQueue = const <OnlineSong>[],
    MoodProfile? mood,
    int length = 12,
  }) {
    if (length <= 0) return const <OnlineSong>[];

    final currentIds = currentQueue
        .map((song) => _normalize(song.id))
        .where((id) => id.isNotEmpty)
        .toSet();

    // Resolve the current mood so the queue remains aligned with the
    // existing mood/session pipeline. Adaptive ranking consumes profile/history.
    mood ??= _mood.inferCurrentProfile();

    final ranked = _adaptive.rank(
      candidates: candidates,
      profile: profile,
      history: history,
      excludedIds: currentIds,
      limit: length * 3,
    );

    final result = <OnlineSong>[];
    final seen = <String>{...currentIds};
    final artistCounts = <String, int>{};

    for (final song in ranked) {
      if (result.length >= length) break;

      final id = _normalize(song.id);
      if (id.isEmpty || !seen.add(id)) continue;

      final artist = _normalize(song.artist);
      final used = artistCounts[artist] ?? 0;
      if (artist.isNotEmpty && used >= 2 && result.length < length - 1) {
        continue;
      }

      result.add(song);
      if (artist.isNotEmpty) artistCounts[artist] = used + 1;
    }

    if (result.length < length) {
      for (final song in ranked) {
        if (result.length >= length) break;
        final id = _normalize(song.id);
        if (id.isEmpty || !seen.add(id)) continue;
        result.add(song);
      }
    }

    return List<OnlineSong>.unmodifiable(result);
  }

  List<OnlineSong> append({
    required Iterable<OnlineSong> candidates,
    required Iterable<OnlineSong> currentQueue,
    required TasteProfile profile,
    required List<ListeningHistoryEntry> history,
    MoodProfile? mood,
    int additional = 5,
  }) {
    if (additional <= 0) {
      return List<OnlineSong>.unmodifiable(currentQueue);
    }

    final existing = currentQueue.toList(growable: false);
    final additions = build(
      candidates: candidates,
      currentQueue: existing,
      profile: profile,
      history: history,
      mood: mood,
      length: additional,
    );

    return List<OnlineSong>.unmodifiable([...existing, ...additions]);
  }

  List<OnlineSong> regenerate({
    required Iterable<OnlineSong> candidates,
    required Iterable<OnlineSong> currentQueue,
    required TasteProfile profile,
    required List<ListeningHistoryEntry> history,
    MoodProfile? mood,
    int length = 12,
  }) {
    return append(
      candidates: candidates,
      currentQueue: currentQueue,
      profile: profile,
      history: history,
      mood: mood,
      additional: length,
    );
  }

  String _normalize(String value) => value.trim().toLowerCase();
}
