import '../models/listening_history_entry.dart';
import '../models/online/online_song.dart';
import 'adaptive_recommendation_service.dart';
import 'mood_energy_service.dart';
import 'session_intelligence_service.dart';
import 'taste_profile_service.dart';

class SmartQueueService {
  SmartQueueService({
    required AdaptiveRecommendationService adaptive,
    required MoodEnergyService mood,
    SessionIntelligenceService? session,
  })  : _adaptive = adaptive,
        _mood = mood,
        _session = session;

  final AdaptiveRecommendationService _adaptive;
  final MoodEnergyService _mood;
  final SessionIntelligenceService? _session;

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
    final activeMood = mood ?? _mood.inferCurrentProfile();

    final ranked = _adaptive.rank(
      candidates: candidates,
      profile: profile,
      history: history,
      excludedIds: currentIds,
      limit: length * 5,
    );

    final contextRanked = _applyContextRanking(ranked, mood: activeMood);

    return _selectTransitionAware(
      contextRanked,
      excludedIds: currentIds,
      length: length,
      mood: activeMood,
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

    return List<OnlineSong>.unmodifiable([
      ...existing,
      ...build(
        candidates: candidates,
        currentQueue: existing,
        profile: profile,
        history: history,
        mood: mood,
        length: additional,
      ),
    ]);
  }

  List<OnlineSong> regenerate({
    required Iterable<OnlineSong> candidates,
    required Iterable<OnlineSong> currentQueue,
    required TasteProfile profile,
    required List<ListeningHistoryEntry> history,
    MoodProfile? mood,
    int length = 12,
  }) {
    if (length <= 0) return List<OnlineSong>.unmodifiable(currentQueue);

    final existing = currentQueue.toList(growable: false);

    // Only candidates not already queued are considered. This makes repeated
    // regeneration safe and prevents a weak track from being reintroduced.
    return append(
      candidates: candidates,
      currentQueue: existing,
      profile: profile,
      history: history,
      mood: mood,
      additional: length,
    );
  }

  List<OnlineSong> _applyContextRanking(
    Iterable<OnlineSong> ranked, {
    required MoodProfile mood,
  }) {
    final scored = <_ContextCandidate>[];

    for (final song in ranked) {
      var score = 0.0;

      final session = _session;
      if (session != null) {
        score += session.scoreOnlineSong(song);
      }

      score += _mood.analyze(song, mood).score;
      scored.add(_ContextCandidate(song, score));
    }

    scored.sort((a, b) {
      final comparison = b.score.compareTo(a.score);
      if (comparison != 0) return comparison;
      return a.song.title.toLowerCase().compareTo(
            b.song.title.toLowerCase(),
          );
    });

    return scored.map((item) => item.song).toList(growable: false);
  }

  List<OnlineSong> _selectTransitionAware(
    Iterable<OnlineSong> ranked, {
    required Set<String> excludedIds,
    required int length,
    required MoodProfile mood,
  }) {
    final pool = ranked.toList(growable: false);
    final result = <OnlineSong>[];
    final seen = <String>{...excludedIds};

    while (result.length < length) {
      _TransitionCandidate? best;

      for (final song in pool) {
        final id = _normalize(song.id);
        if (id.isEmpty || seen.contains(id)) continue;

        final score = _transitionScore(
          song,
          previous: result.isEmpty ? null : result.last,
          mood: mood,
        );

        final candidate = _TransitionCandidate(song, score);
        if (best == null ||
            candidate.score > best.score ||
            (candidate.score == best.score &&
                song.title.toLowerCase().compareTo(
                      best.song.title.toLowerCase(),
                    ) <
                    0)) {
          best = candidate;
        }
      }

      if (best == null) break;

      result.add(best.song);
      seen.add(_normalize(best.song.id));
    }

    return List<OnlineSong>.unmodifiable(result);
  }

  double _transitionScore(
    OnlineSong song, {
    required OnlineSong? previous,
    required MoodProfile mood,
  }) {
    if (previous == null) return 0.0;

    final artist = _normalize(song.artist);
    final previousArtist = _normalize(previous.artist);
    final album = _normalize(song.album);
    final previousAlbum = _normalize(previous.album);

    var score = 0.0;

    if (artist.isNotEmpty && artist == previousArtist) score -= 8.0;
    if (album.isNotEmpty && album == previousAlbum) score -= 3.0;

    final currentMood = _mood.analyze(song, mood);
    final previousMood = _mood.analyze(previous, mood);
    final moodDelta = (currentMood.score - previousMood.score).abs();

    if (moodDelta <= 2.0) {
      score += 1.0;
    } else if (moodDelta >= 8.0) {
      score -= 1.5;
    }

    return score;
  }

  Set<String> _ids(Iterable<OnlineSong> songs) => songs
      .map((song) => _normalize(song.id))
      .where((id) => id.isNotEmpty)
      .toSet();

  String _normalize(String value) => value.trim().toLowerCase();
}

class _ContextCandidate {
  const _ContextCandidate(this.song, this.score);
  final OnlineSong song;
  final double score;
}

class _TransitionCandidate {
  const _TransitionCandidate(this.song, this.score);
  final OnlineSong song;
  final double score;
}
