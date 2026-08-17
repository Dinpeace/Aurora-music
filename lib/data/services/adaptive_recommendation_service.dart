import '../models/listening_history_entry.dart';
import '../models/online/online_song.dart';
import 'taste_profile_service.dart';

/// Applies adaptive behavior on top of Aurora's existing TasteProfile.
///
/// The base taste profile already accounts for plays, recency, completion,
/// skips, favorites, artists, albums and inferred genres. This layer adds
/// explicit exploration controls and per-track penalties so recommendations
/// can adapt without changing the underlying profile format.
class AdaptiveRecommendationService {
  AdaptiveRecommendationService({
    this.explorationWeight = 0.18,
    this.repetitionPenalty = 0.35,
    this.skipPenalty = 2.5,
  });

  final double explorationWeight;
  final double repetitionPenalty;
  final double skipPenalty;

  List<OnlineSong> rank({
    required Iterable<OnlineSong> candidates,
    required TasteProfile profile,
    required List<ListeningHistoryEntry> history,
    Set<String> excludedIds = const <String>{},
    int limit = 20,
  }) {
    if (limit <= 0) return const <OnlineSong>[];

    final excluded = excludedIds.map(_normalize).toSet();
    final historyById = <String, ListeningHistoryEntry>{
      for (final entry in history) _normalize(entry.song.id): entry,
    };

    final scored = <_Candidate>[];

    for (final song in candidates) {
      final id = _normalize(song.id);
      if (id.isEmpty || excluded.contains(id)) continue;

      final base = TasteProfileService().rankSong(song, profile);
      final historyEntry = historyById[id];
      final adaptive = _adaptiveAdjustment(historyEntry);
      final exploration = historyEntry == null
          ? _noveltyBonus(song, profile)
          : 0.0;

      scored.add(
        _Candidate(
          song: song,
          score: base + adaptive + exploration,
        ),
      );
    }

    scored.sort((a, b) {
      final score = b.score.compareTo(a.score);
      if (score != 0) return score;
      return a.song.title.toLowerCase().compareTo(b.song.title.toLowerCase());
    });

    final selected = <OnlineSong>[];
    final artistCounts = <String, int>{};

    for (final candidate in scored) {
      if (selected.length >= limit) break;

      final artist = _normalize(candidate.song.artist);
      final count = artistCounts[artist] ?? 0;

      // Keep a healthy amount of artist diversity.
      if (artist.isNotEmpty && count >= 3 && scored.length > limit) {
        continue;
      }

      selected.add(candidate.song);
      if (artist.isNotEmpty) {
        artistCounts[artist] = count + 1;
      }
    }

    // If diversity filtering left us short, fill from the remaining ranking.
    if (selected.length < limit) {
      final selectedIds = selected.map((song) => _normalize(song.id)).toSet();
      for (final candidate in scored) {
        if (selected.length >= limit) break;
        if (selectedIds.add(_normalize(candidate.song.id))) {
          selected.add(candidate.song);
        }
      }
    }

    return List<OnlineSong>.unmodifiable(selected);
  }

  double _adaptiveAdjustment(ListeningHistoryEntry? entry) {
    if (entry == null) return 0.0;

    final skips = entry.skipCount.clamp(0, 20).toDouble();
    final plays = entry.playCount.clamp(0, 50).toDouble();

    // Frequently skipped tracks should fall down the list; repeatedly played
    // tracks get a smaller positive reinforcement.
    return (plays * repetitionPenalty) - (skips * skipPenalty);
  }

  double _noveltyBonus(
    OnlineSong song,
    TasteProfile profile,
  ) {
    final artist = _normalize(song.artist);
    final album = _normalize(song.album);

    var bonus = 0.0;

    if (!profile.favoriteArtists.contains(artist)) {
      bonus += 1.5 * explorationWeight;
    }
    if (!profile.albums.containsKey(album)) {
      bonus += 1.0 * explorationWeight;
    }

    return bonus;
  }

  String _normalize(String value) => value.trim().toLowerCase();
}

class _Candidate {
  const _Candidate({
    required this.song,
    required this.score,
  });

  final OnlineSong song;
  final double score;
}
