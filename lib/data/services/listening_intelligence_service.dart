import '../models/listening_history_entry.dart';
import '../models/song.dart';
import 'listening_history_service.dart';
import 'taste_profile_service.dart';

/// Connects persistent listening history with Aurora's taste-profile layer.
///
/// This is the bridge used by recommendation features: history is persisted
/// by ListeningHistoryService, while TasteProfileService remains responsible
/// for scoring and profile construction.
class ListeningIntelligenceService {
  ListeningIntelligenceService({
    required ListeningHistoryService history,
    required TasteProfileService taste,
  })  : _history = history,
        _taste = taste;

  final ListeningHistoryService _history;
  final TasteProfileService _taste;

  Future<TasteProfile> buildProfile({
    required Iterable<Song> library,
    Iterable<Song> favorites = const <Song>[],
  }) async {
    await _history.initialize();

    final favoriteList = favorites.toList(growable: false);
    final favoriteArtists = favoriteList
        .map((song) => song.artist)
        .where((artist) => artist.trim().isNotEmpty)
        .toList(growable: false);
    final favoriteIds = favoriteList
        .map((song) => song.id)
        .where((id) => id.trim().isNotEmpty)
        .toList(growable: false);

    final history = _mergeLibraryMetadata(
      entries: _history.entries,
      library: library,
    );

    return _taste.build(
      history: history,
      favoriteArtists: favoriteArtists,
      favoriteIds: favoriteIds,
    );
  }

  List<ListeningHistoryEntry> _mergeLibraryMetadata({
    required List<ListeningHistoryEntry> entries,
    required Iterable<Song> library,
  }) {
    final byId = <String, Song>{
      for (final song in library) _normalize(song.id): song,
    };

    return entries.map((entry) {
      final librarySong = byId[_normalize(entry.song.id)];
      if (librarySong == null) return entry;

      return entry.copyWith(
        song: entry.song.copyWith(
          title: librarySong.title,
          artist: librarySong.artist,
          album: librarySong.album,
          artwork: librarySong.artwork,
          audioUrl: librarySong.audioUrl,
          duration: librarySong.duration,
          favorite: librarySong.favorite,
        ),
      );
    }).toList(growable: false);
  }

  String _normalize(String value) => value.trim().toLowerCase();
}
