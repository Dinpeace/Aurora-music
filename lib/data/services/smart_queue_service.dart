import '../models/listening_history_entry.dart';
import '../models/online/online_song.dart';
import 'adaptive_recommendation_service.dart';
import 'mood_energy_service.dart';
import 'session_intelligence_service.dart';
import 'taste_profile_service.dart';

enum ListeningMode {
  balanced,
  focus,
  chill,
  discovery,
  favorites,
}

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
    ListeningMode mode = ListeningMode.balanced,
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
      limit: length * 6,
    );

    final contextRanked = _applyContextRanking(
      ranked,
      mood: activeMood,
      mode: mode,
      profile: profile,
    );

    final modeRanked = _applyModePriority(
      contextRanked,
      mode: mode,
      profile: profile,
    );

    return _selectTransitionAware(
      modeRanked,
      excludedIds: currentIds,
      length: length,
      mood: activeMood,
      mode: mode,
    );
  }

  List<OnlineSong> append({
    required Iterable<OnlineSong> candidates,
    required Iterable<OnlineSong> currentQueue,
    required TasteProfile profile,
    required List<ListeningHistoryEntry> history,
    MoodProfile? mood,
    ListeningMode mode = ListeningMode.balanced,
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
        mode: mode,
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
    ListeningMode mode = ListeningMode.balanced,
    int length = 12,
  }) {
    if (length <= 0) return List<OnlineSong>.unmodifiable(currentQueue);

    return append(
      candidates: candidates,
      currentQueue: currentQueue,
      profile: profile,
      history: history,
      mood: mood,
      mode: mode,
      additional: length,
    );
  }

  List<OnlineSong> _applyContextRanking(
    Iterable<OnlineSong> ranked, {
    required MoodProfile mood,
    required ListeningMode mode,
    required TasteProfile profile,
  }) {
    final scored = <_ContextCandidate>[];

    for (final song in ranked) {
      var score = 0.0;
      final session = _session;

      if (session != null) {
        score += session.scoreOnlineSong(song);
      }

      score += _mood.analyze(song, mood).score;
      score += _modeScore(song, mode, profile);

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

  double _modeScore(
    OnlineSong song,
    ListeningMode mode,
    TasteProfile profile,
  ) {
    final artist = _normalize(song.artist);
    final album = _normalize(song.album);
    final isFavoriteArtist = profile.favoriteArtists.contains(artist);
    final isKnownAlbum = profile.albums.containsKey(album);

    switch (mode) {
      case ListeningMode.balanced:
        return 0.0;
      case ListeningMode.favorites:
        return (isFavoriteArtist ? 5.0 : -1.5) +
            (isKnownAlbum ? 1.0 : 0.0);
      case ListeningMode.discovery:
        // Discovery must be strong enough to overcome taste, mood and
        // session familiarity signals when an unknown candidate exists.
        return (isFavoriteArtist ? -30.0 : 30.0) +
            (isKnownAlbum ? -5.0 : 5.0);
      case ListeningMode.focus:
        return _focusScore(song);
      case ListeningMode.chill:
        return _chillScore(song);
    }
  }

  double _focusScore(OnlineSong song) {
    final title = '${song.title} ${song.album}'.toLowerCase();
    var score = 0.0;

    if (title.contains('instrumental') ||
        title.contains('ambient') ||
        title.contains('lofi') ||
        title.contains('focus')) {
      score += 3.0;
    }

    if (title.contains('remix') || title.contains('live')) {
      score -= 1.0;
    }

    return score;
  }

  double _chillScore(OnlineSong song) {
    final title = '${song.title} ${song.album}'.toLowerCase();
    var score = 0.0;

    if (title.contains('acoustic') ||
        title.contains('chill') ||
        title.contains('ambient') ||
        title.contains('lofi') ||
        title.contains('unplugged')) {
      score += 3.0;
    }

    if (title.contains('hardstyle') ||
        title.contains('metal') ||
        title.contains('aggressive')) {
      score -= 2.0;
    }

    return score;
  }

  List<OnlineSong> _applyModePriority(
    Iterable<OnlineSong> ranked, {
    required ListeningMode mode,
    required TasteProfile profile,
  }) {
    final songs = ranked.toList(growable: false);
    if (mode == ListeningMode.balanced || songs.length < 2) {
      return songs;
    }

    final scored = <_ContextCandidate>[];

    for (final song in songs) {
      final artist = _normalize(song.artist);
      final album = _normalize(song.album);
      final favorite = profile.favoriteArtists.contains(artist);
      final knownAlbum = profile.albums.containsKey(album);

      double priority;

      switch (mode) {
        case ListeningMode.discovery:
          // Discovery is an ordering mode, not a small score adjustment.
          // Unknown artists/albums are placed before familiar ones.
          priority = (favorite ? 0.0 : 1000.0) +
              (knownAlbum ? 0.0 : 100.0);
          break;
        case ListeningMode.favorites:
          priority = (favorite ? 1000.0 : 0.0) +
              (knownAlbum ? 100.0 : 0.0);
          break;
        case ListeningMode.focus:
        case ListeningMode.chill:
        case ListeningMode.balanced:
          priority = 0.0;
          break;
      }

      scored.add(_ContextCandidate(song, priority));
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
    required ListeningMode mode,
  }) {
    final pool = ranked.toList(growable: false);
    final result = <OnlineSong>[];
    final seen = <String>{...excludedIds};

    while (result.length < length) {
      _TransitionCandidate? best;

      for (var index = 0; index < pool.length; index++) {
        final song = pool[index];
        final id = _normalize(song.id);
        if (id.isEmpty || seen.contains(id)) continue;

        final transitionScore = _transitionScore(
          song,
          previous: result.isEmpty ? null : result.last,
          mood: mood,
          mode: mode,
        );

        // Preserve the upstream adaptive/context/mode ranking. Transition
        // scoring is only a tie-break/context adjustment; it must not discard
        // an explicit mode ordering such as Discovery.
        final rankScore = (pool.length - index) * 10.0;
        final score = rankScore + transitionScore;

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
    required ListeningMode mode,
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

    // Focus and chill favor smooth transitions; discovery tolerates more change.
    if (mode == ListeningMode.focus || mode == ListeningMode.chill) {
      if (moodDelta <= 4.0) score += 1.5;
      if (moodDelta >= 8.0) score -= 1.0;
    } else if (mode == ListeningMode.discovery && moodDelta >= 4.0) {
      score += 0.75;
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
