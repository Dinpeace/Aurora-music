import '../models/song.dart';
import '../sources/demo_music_source.dart';

class MusicRepository {
  const MusicRepository();

  List<Song> getRecentlyPlayed() {
    return List.unmodifiable(DemoMusicSource.recentlyPlayed);
  }

  List<Song> getTrending() {
    return List.unmodifiable(DemoMusicSource.trending);
  }

  List<Song> getNewReleases() {
    return List.unmodifiable(DemoMusicSource.newReleases);
  }

  List<Song> getAllSongs() {
    return [
      ...DemoMusicSource.recentlyPlayed,
      ...DemoMusicSource.trending,
      ...DemoMusicSource.newReleases,
    ];
  }

  Song? getSongById(String id) {
    try {
      return getAllSongs().firstWhere((song) => song.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Song> searchSongs(String query) {
    if (query.trim().isEmpty) {
      return getAllSongs();
    }

    final search = query.toLowerCase();

    return getAllSongs().where((song) {
      return song.title.toLowerCase().contains(search) ||
          song.artist.toLowerCase().contains(search) ||
          song.album.toLowerCase().contains(search);
    }).toList();
  }
}