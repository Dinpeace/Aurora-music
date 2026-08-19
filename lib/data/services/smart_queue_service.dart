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

    final currentIds = _ids(currentQueue);
    mood ??= _mood.inferCurrentProfile();

    final ranked = _adaptive.rank(
      candidates: candidates,
      profile: profile,
      history: history,
      excludedIds: currentIds,
      limit: length * 3,
    );

    return _select(
      ranked,
      excludedIds: currentIds,
      length: length,
    );
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

  /// Rebuilds only the portion after the current queue, preserving the
  /// currently playing/queued songs and preventing duplicates.
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

  Set<String> _ids(Iterable<OnlineSong> songs) => songs
      .map((song) => _normalize(song.id))
      .where((id) => id.isNotEmpty)
      .toSet();

  List<OnlineSong> _select(
    Iterable<OnlineSong> ranked, {
    required Set<String> excludedIds,
    required int length,
  }) {
    final result = <OnlineSong>[];
    final seen = <String>{...excludedIds};
    final artistCounts = <String, int>{};

    for (final song in ranked) {
      if (result.length >= length) break;

      final id = _normalize(song.id);
      if (id.isEmpty || !seen.add(id)) continue;

      final artist = _normalize(song.artist);
      final count = artistCounts[artist] ?? 0;

      // Avoid artist monopolies while still allowing the final slot to be
      // filled when the candidate pool is small.
      if (artist.isNotEmpty && count >= 2 && result.length < length - 1) {
        continue;
      }

      result.add(song);
      if (artist.isNotEmpty) artistCounts[artist] = count + 1;
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

  String _normalize(String value) => value.trim().toLowerCase();
}
