import '../models/listening_history_entry.dart';
import '../models/online/online_song.dart';

class TasteProfileService {
  TasteProfile build({
    required List<ListeningHistoryEntry> history,
    required List<String> favoriteArtists,
    required List<String> favoriteIds,
  }) {
    final genreScores = <String, double>{};
    final artistScores = <String, double>{};
    final albumScores = <String, double>{};
    final favoriteArtistKeys = favoriteArtists
        .map(_normalize)
        .where((value) => value.isNotEmpty)
        .toSet();
    final favoriteIdKeys = favoriteIds
        .map(_normalize)
        .where((value) => value.isNotEmpty)
        .toSet();

    for (final entry in history) {
      final song = entry.song;
      final base = _historyWeight(entry);
      final artist = _normalize(song.artist);
      final album = _normalize(song.album);

      if (artist.isNotEmpty) {
        artistScores[artist] = (artistScores[artist] ?? 0) + base;
      }
      if (album.isNotEmpty) {
        albumScores[album] = (albumScores[album] ?? 0) + base * 0.55;
      }

      for (final genre in _inferGenres(
        '${song.title} ${song.artist} ${song.album}',
      )) {
        genreScores[genre] = (genreScores[genre] ?? 0) + base;
      }
    }

    for (final artist in favoriteArtistKeys) {
      artistScores[artist] = (artistScores[artist] ?? 0) + 12.0;
    }

    for (final id in favoriteIdKeys) {
      // Favorite IDs are used as a strong track-level signal by rankSong.
      // The set is retained in the profile rather than converted into a fake genre.
      if (id.isEmpty) continue;
    }

    return TasteProfile(
      genres: _topScores(genreScores),
      artists: _topScores(artistScores),
      albums: _topScores(albumScores),
      favoriteArtists: favoriteArtistKeys,
      favoriteIds: favoriteIdKeys,
    );
  }

  List<OnlineSong> rank(
    Iterable<OnlineSong> songs,
    TasteProfile profile, {
    Set<String> excludedIds = const <String>{},
  }) {
    final excluded = excludedIds.map(_normalize).toSet();
    final scored = <_TasteCandidate>[];
    final artistCounts = <String, int>{};

    for (final song in songs) {
      final id = _normalize(song.id);
      if (id.isEmpty || excluded.contains(id)) continue;

      final score = rankSong(song, profile);
      scored.add(_TasteCandidate(song: song, score: score));
      final artist = _normalize(song.artist);
      if (artist.isNotEmpty) {
        artistCounts[artist] = (artistCounts[artist] ?? 0) + 1;
      }
    }

    scored.sort((a, b) {
      final comparison = b.score.compareTo(a.score);
      if (comparison != 0) return comparison;
      return a.song.title.toLowerCase().compareTo(b.song.title.toLowerCase());
    });

    final selected = <OnlineSong>[];
    final selectedArtists = <String, int>{};
    for (final candidate in scored) {
      final artist = _normalize(candidate.song.artist);
      final used = selectedArtists[artist] ?? 0;
      if (artist.isNotEmpty && used >= 3 && selected.length < scored.length - 1) {
        continue;
      }
      selected.add(candidate.song);
      if (artist.isNotEmpty) selectedArtists[artist] = used + 1;
    }

    return selected;
  }

  double rankSong(OnlineSong song, TasteProfile profile) {
    final artist = _normalize(song.artist);
    final album = _normalize(song.album);
    final id = _normalize(song.id);
    final text = '${song.title} ${song.artist} ${song.album}';
    final genres = _inferGenres(text);

    var score = 0.0;

    if (profile.favoriteIds.contains(id)) score += 24.0;
    if (profile.favoriteArtists.contains(artist)) score += 16.0;

    score += (profile.artists[artist] ?? 0) * 1.2;
    score += (profile.albums[album] ?? 0) * 0.7;

    for (final genre in genres) {
      score += (profile.genres[genre] ?? 0) * 1.4;
    }

    score += _metadataAffinity(text, profile);
    return score;
  }

  double _metadataAffinity(String text, TasteProfile profile) {
    final lower = text.toLowerCase();
    var score = 0.0;
    for (final genre in profile.genres.keys.take(3)) {
      if (lower.contains(genre)) score += 1.5;
    }
    return score;
  }

  double _historyWeight(ListeningHistoryEntry entry) {
    final days = DateTime.now().difference(entry.lastPlayed).inHours / 24.0;
    final recency = 1.0 / (1.0 + days.clamp(0.0, 365.0));
    final plays = entry.playCount.clamp(0, 50).toDouble();
    final skips = entry.skipCount.clamp(0, 20).toDouble();
    final completion = entry.duration > Duration.zero &&
            entry.position >= entry.duration * 0.7
        ? 1.5
        : 0.0;
    return plays * 2.0 + recency * 5.0 + completion - skips * 1.75;
  }

  Map<String, double> _topScores(Map<String, double> values) {
    final entries = values.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map<String, double>.fromEntries(entries.take(12));
  }

  Set<String> _inferGenres(String text) {
    final lower = text.toLowerCase();
    const mapping = <String, List<String>>{
      'pop': ['pop', 'top 40', 'radio pop'],
      'rock': ['rock', 'alternative', 'indie rock', 'punk', 'metal'],
      'hip hop': ['hip hop', 'hip-hop', 'rap', 'trap'],
      'r&b': ['r&b', 'rnb', 'soul'],
      'electronic': ['edm', 'electronic', 'dance', 'house', 'techno', 'dubstep'],
      'lofi': ['lofi', 'lo-fi', 'chillhop'],
      'acoustic': ['acoustic', 'unplugged', 'singer-songwriter'],
      'classical': ['classical', 'orchestra', 'symphony', 'piano'],
      'jazz': ['jazz', 'swing', 'bebop'],
      'country': ['country', 'americana'],
      'indie': ['indie', 'bedroom pop'],
      'soundtrack': ['soundtrack', 'ost', 'original motion picture'],
    };

    final result = <String>{};
    mapping.forEach((genre, keywords) {
      if (keywords.any(lower.contains)) result.add(genre);
    });
    return result;
  }

  String _normalize(String value) => value.trim().toLowerCase();
}

class TasteProfile {
  const TasteProfile({
    required this.genres,
    required this.artists,
    required this.albums,
    required this.favoriteArtists,
    required this.favoriteIds,
  });

  final Map<String, double> genres;
  final Map<String, double> artists;
  final Map<String, double> albums;
  final Set<String> favoriteArtists;
  final Set<String> favoriteIds;

  bool get isEmpty =>
      genres.isEmpty && artists.isEmpty && albums.isEmpty;

  List<String> get topGenres => genres.keys.take(5).toList(growable: false);
  List<String> get topArtists => artists.keys.take(5).toList(growable: false);
}

class _TasteCandidate {
  const _TasteCandidate({required this.song, required this.score});

  final OnlineSong song;
  final double score;
}
