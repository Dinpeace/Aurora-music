import '../models/song.dart';

class LocalMusicService {
  const LocalMusicService();

  /// Temporary stub.
  /// Will be replaced with the real MediaStore implementation.
  Future<bool> requestPermission() async {
    return true;
  }

  /// Returns an empty list until the scanner is implemented.
  Future<List<Song>> getSongs() async {
    return const [];
  }

  /// Placeholder for future album support.
  Future<List<dynamic>> getAlbums() async {
    return const [];
  }

  /// Placeholder for future artist support.
  Future<List<dynamic>> getArtists() async {
    return const [];
  }

  /// Placeholder for future playlist support.
  Future<List<dynamic>> getPlaylists() async {
    return const [];
  }
}