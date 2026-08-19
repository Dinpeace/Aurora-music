import '../models/listening_history_entry.dart';
import '../models/online/online_song.dart';
import 'taste_profile_service.dart';

class PersonalizedDiscoveryService {
  const PersonalizedDiscoveryService({
    this.discoveryWeight = 1.50,
    this.familiarityWeight = 0.35,
    this.recentArtistPenalty = 1.50,
    this.recentTrackPenalty = 100.00,
  });

  final double discoveryWeight;
  final double familiarityWeight;
  final double recentArtistPenalty;
  final double recentTrackPenalty;

  List<OnlineSong> rank({
    required Iterable<OnlineSong> candidates,
    required TasteProfile profile,
    required List<ListeningHistoryEntry> history,
    Set<String> excludedIds = const <String>{},
    int limit = 20,
  }) {
    if (limit <= 0) return const <OnlineSong>[];

    final excluded = excludedIds.map(_normalize).toSet();

    final recent = [...history]
      ..sort((a, b) => b.lastPlayed.compareTo(a.lastPlayed));

    final recentIds = recent
        .take(20)
        .map((entry) => _normalize(entry.song.id))
        .toSet();

    final recentArtists = recent
        .take(20)
        .map((entry) => _normalize(entry.song.artist))
        .where((artist) => artist.isNotEmpty)
        .toSet();

    final historyIds =
        history.map((entry) => _normalize(entry.song.id)).toSet();

    final scored = <_Candidate>[];

    for (final song in candidates) {
      final id = _normalize(song.id);
      if (id.isEmpty || excluded.contains(id)) continue;

      final artist = _normalize(song.artist);
      final album = _normalize(song.album);
      final base = TasteProfileService().rankSong(song, profile);

      final knownArtist = profile.artists.containsKey(artist);
      final knownAlbum = profile.albums.containsKey(album);
      final knownTrack = historyIds.contains(id);

      var familiarity = 0.0;
      if (knownArtist) familiarity += 1.0;
      if (knownAlbum) familiarity += 0.6;
      if (knownTrack) familiarity += 0.8;

      var discovery = 0.0;
      if (!knownArtist) discovery += 1.0;
      if (!knownAlbum) discovery += 0.7;
      if (!knownTrack) discovery += 0.8;

      var penalty = 0.0;

      // Exact recent repetition is intentionally much stronger than general
      // artist familiarity. Fresh candidates should get a chance.
      if (recentIds.contains(id)) {
        penalty += recentTrackPenalty;
      }

      if (recentArtists.contains(artist)) {
        penalty += recentArtistPenalty;
      }

      final score = base +
          (familiarity * familiarityWeight) +
          (discovery * discoveryWeight) -
          penalty;

      scored.add(_Candidate(song, score));
    }

    scored.sort((a, b) {
      final comparison = b.score.compareTo(a.score);
      if (comparison != 0) return comparison;
      return a.song.title.toLowerCase().compareTo(
            b.song.title.toLowerCase(),
          );
    });

    return List<OnlineSong>.unmodifiable(
      scored.take(limit).map((candidate) => candidate.song),
    );
  }

  String _normalize(String value) => value.trim().toLowerCase();
}

class _Candidate {
  const _Candidate(this.song, this.score);

  final OnlineSong song;
  final double score;
}
