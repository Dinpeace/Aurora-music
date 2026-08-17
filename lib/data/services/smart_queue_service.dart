import '../models/online/online_song.dart';
import 'mood_energy_service.dart';
import 'recommendation_engine.dart';
import 'taste_profile_service.dart';

/// Builds a continuation queue from Aurora's existing recommendation signals.
///
/// This service is UI-agnostic: it returns OnlineSong objects and never starts
/// playback or mutates the player's queue.
class SmartQueueService {
  SmartQueueService({
    required RecommendationEngine recommendations,
    required MoodEnergyService mood,
  })  : _recommendations = recommendations,
        _mood = mood;

  final RecommendationEngine _recommendations;
  final MoodEnergyService _mood;

  List<OnlineSong> build({
    required Iterable<OnlineSong> candidates,
    required TasteProfile profile,
    Iterable<OnlineSong> currentQueue = const <OnlineSong>[],
    MoodProfile? mood,
    int length = 12,
  }) {
    if (length <= 0) return const <OnlineSong>[];

    final currentIds = currentQueue
        .map((song) => _normalize(song.id))
        .where((id) => id.isNotEmpty)
        .toSet();

    final selectedMood = mood ?? _mood.inferCurrentProfile();

    final ranked = _recommendations.rank(
      candidates: candidates,
      profile: profile,
      mood: selectedMood,
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
    MoodProfile? mood,
    int additional = 5,
  }) {
    if (additional <= 0) return List<OnlineSong>.unmodifiable(currentQueue);

    final existing = currentQueue.toList(growable: false);
    final additions = build(
      candidates: candidates,
      profile: profile,
      currentQueue: existing,
      mood: mood,
      length: additional,
    );

    return List<OnlineSong>.unmodifiable([
      ...existing,
      ...additions,
    ]);
  }

  List<OnlineSong> regenerate({
    required Iterable<OnlineSong> candidates,
    required Iterable<OnlineSong> currentQueue,
    required TasteProfile profile,
    MoodProfile? mood,
    int length = 12,
  }) {
    final current = currentQueue.toList(growable: false);
    return append(
      candidates: candidates,
      currentQueue: current,
      profile: profile,
      mood: mood,
      additional: length,
    );
  }

  String _normalize(String value) => value.trim().toLowerCase();
}
