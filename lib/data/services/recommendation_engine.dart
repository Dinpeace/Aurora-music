import '../models/online/online_song.dart';
import 'mood_energy_service.dart';
import 'session_intelligence_service.dart';
import 'taste_profile_service.dart';

/// Combines Aurora's existing taste, mood, and session signals into one
/// deterministic recommendation pipeline.
///
/// This service deliberately does not fetch music or own UI state. Pass it a
/// candidate list from the existing online/local provider and it returns the
/// candidates ranked for the listener.
class RecommendationEngine {
  RecommendationEngine({
    required TasteProfileService taste,
    required MoodEnergyService mood,
    required SessionIntelligenceService session,
  })  : _taste = taste,
        _mood = mood,
        _session = session;

  final TasteProfileService _taste;
  final MoodEnergyService _mood;
  final SessionIntelligenceService _session;

  /// Returns candidates ordered from most to least relevant.
  List<OnlineSong> rank({
    required Iterable<OnlineSong> candidates,
    required TasteProfile profile,
    MoodProfile? mood,
    Set<String> excludedIds = const <String>{},
    int limit = 20,
  }) {
    final selectedMood = mood ?? _mood.inferCurrentProfile();
    final excluded = {
      ...excludedIds.map(_normalize),
      ..._session.rejectedSongIds.map(_normalize),
    };

    final scored = <_RecommendationCandidate>[];

    for (final song in candidates) {
      final id = _normalize(song.id);
      if (id.isEmpty || excluded.contains(id)) continue;

      final tasteScore = _taste.rankSong(song, profile);
      final moodMatch = _mood.analyze(song, selectedMood);
      final sessionScore = _session.scoreOnlineSong(song);

      // Taste is the strongest long-term signal. Mood and session signals
      // adapt the result without overpowering established preferences.
      final score =
          (tasteScore * 0.55) +
          (moodMatch.score * 0.25) +
          (sessionScore * 0.20);

      scored.add(
        _RecommendationCandidate(
          song: song,
          score: score,
          tasteScore: tasteScore,
          moodScore: moodMatch.score,
          sessionScore: sessionScore,
        ),
      );
    }

    scored.sort(_compareCandidates);

    final result = <OnlineSong>[];
    final artistCounts = <String, int>{};

    for (final candidate in scored) {
      if (result.length >= limit) break;

      final artist = _normalize(candidate.song.artist);
      final used = artistCounts[artist] ?? 0;

      // Prevent one artist from taking over a recommendation shelf.
      if (artist.isNotEmpty && used >= 3 && result.length < limit - 1) {
        continue;
      }

      result.add(candidate.song);
      if (artist.isNotEmpty) {
        artistCounts[artist] = used + 1;
      }
    }

    return result;
  }

  /// Produces a personalized shelf without requiring a UI-specific model.
  List<OnlineSong> recommend({
    required Iterable<OnlineSong> candidates,
    required TasteProfile profile,
    MoodProfile? mood,
    Set<String> excludedIds = const <String>{},
    int limit = 10,
  }) {
    return rank(
      candidates: candidates,
      profile: profile,
      mood: mood,
      excludedIds: excludedIds,
      limit: limit,
    );
  }

  /// Returns a human-readable explanation for why a song ranked well.
  List<String> reasons({
    required OnlineSong song,
    required TasteProfile profile,
    MoodProfile? mood,
  }) {
    final selectedMood = mood ?? _mood.inferCurrentProfile();
    final reasons = <String>[];

    final artist = _normalize(song.artist);
    final album = _normalize(song.album);
    final id = _normalize(song.id);

    if (profile.favoriteIds.contains(id)) {
      reasons.add('In your favorites');
    } else if (profile.favoriteArtists.contains(artist)) {
      reasons.add('From an artist you like');
    }

    if (artist.isNotEmpty && profile.artists.containsKey(artist)) {
      reasons.add('Matches your listening taste');
    }

    if (album.isNotEmpty && profile.albums.containsKey(album)) {
      reasons.add('Fits albums you enjoy');
    }

    final moodMatch = _mood.analyze(song, selectedMood);
    if (moodMatch.score > 0) {
      reasons.add('Fits your ${selectedMood.title.toLowerCase()} mood');
    }

    final sessionScore = _session.scoreOnlineSong(song);
    if (sessionScore > 0) {
      reasons.add('Fits this listening session');
    }

    if (reasons.isEmpty) {
      reasons.add('A discovery picked for you');
    }

    return List<String>.unmodifiable(reasons);
  }

  static int _compareCandidates(
    _RecommendationCandidate a,
    _RecommendationCandidate b,
  ) {
    final score = b.score.compareTo(a.score);
    if (score != 0) return score;

    final taste = b.tasteScore.compareTo(a.tasteScore);
    if (taste != 0) return taste;

    final mood = b.moodScore.compareTo(a.moodScore);
    if (mood != 0) return mood;

    return a.song.title.toLowerCase().compareTo(
          b.song.title.toLowerCase(),
        );
  }

  String _normalize(String value) => value.trim().toLowerCase();
}

class _RecommendationCandidate {
  const _RecommendationCandidate({
    required this.song,
    required this.score,
    required this.tasteScore,
    required this.moodScore,
    required this.sessionScore,
  });

  final OnlineSong song;
  final double score;
  final double tasteScore;
  final double moodScore;
  final double sessionScore;
}
