import '../models/listening_history_entry.dart';
import 'taste_profile_service.dart';

/// Produces lightweight, UI-ready listening insights from Aurora's existing
/// history and taste profile. This service does not persist anything and does
/// not depend on the player or Flutter UI.
class ListeningInsightsService {
  ListeningInsights summarize({
    required List<ListeningHistoryEntry> history,
    required TasteProfile profile,
  }) {
    var totalPlays = 0;
    var totalSkips = 0;
    var completedTracks = 0;
    var listeningMilliseconds = 0;

    final artistPlays = <String, int>{};
    final albumPlays = <String, int>{};

    for (final entry in history) {
      final plays = entry.playCount.clamp(0, 100000);
      final skips = entry.skipCount.clamp(0, 100000);

      totalPlays += plays;
      totalSkips += skips;

      final duration = entry.duration;
      final position = entry.position;
      if (duration > Duration.zero) {
        final listened = position > duration ? duration : position;
        listeningMilliseconds += listened.inMilliseconds;

        if (position >= duration * 0.7) {
          completedTracks++;
        }
      }

      final artist = _normalize(entry.song.artist);
      if (artist.isNotEmpty) {
        artistPlays[artist] = (artistPlays[artist] ?? 0) + plays;
      }

      final album = _normalize(entry.song.album);
      if (album.isNotEmpty) {
        albumPlays[album] = (albumPlays[album] ?? 0) + plays;
      }
    }

    return ListeningInsights(
      totalTracks: history.length,
      totalPlays: totalPlays,
      totalSkips: totalSkips,
      completionRate: totalPlays == 0
          ? 0.0
          : (completedTracks / history.length).clamp(0.0, 1.0),
      skipRate: totalPlays == 0
          ? 0.0
          : (totalSkips / totalPlays).clamp(0.0, 1.0),
      listeningTime: Duration(milliseconds: listeningMilliseconds),
      topArtists: _top(artistPlays),
      topAlbums: _top(albumPlays),
      topGenres: profile.topGenres,
      favoriteArtistCount: profile.favoriteArtists.length,
      favoriteTrackCount: profile.favoriteIds.length,
    );
  }

  List<InsightItem> _top(Map<String, int> values) {
    final entries = values.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return entries
        .take(5)
        .map((entry) => InsightItem(name: entry.key, plays: entry.value))
        .toList(growable: false);
  }

  String _normalize(String value) => value.trim().toLowerCase();
}

class ListeningInsights {
  const ListeningInsights({
    required this.totalTracks,
    required this.totalPlays,
    required this.totalSkips,
    required this.completionRate,
    required this.skipRate,
    required this.listeningTime,
    required this.topArtists,
    required this.topAlbums,
    required this.topGenres,
    required this.favoriteArtistCount,
    required this.favoriteTrackCount,
  });

  final int totalTracks;
  final int totalPlays;
  final int totalSkips;
  final double completionRate;
  final double skipRate;
  final Duration listeningTime;
  final List<InsightItem> topArtists;
  final List<InsightItem> topAlbums;
  final List<String> topGenres;
  final int favoriteArtistCount;
  final int favoriteTrackCount;

  bool get hasData => totalTracks > 0 || totalPlays > 0;
}

class InsightItem {
  const InsightItem({
    required this.name,
    required this.plays,
  });

  final String name;
  final int plays;
}
