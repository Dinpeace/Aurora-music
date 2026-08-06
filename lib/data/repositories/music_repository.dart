import '../models/song.dart';
import '../services/local_music_service.dart';

class MusicRepository {
  MusicRepository({
    LocalMusicService? localMusicService,
  }) : _localMusicService =
            localMusicService ?? const LocalMusicService();

  final LocalMusicService _localMusicService;

  Future<bool> requestPermission() async {
    return _localMusicService.requestPermission();
  }

  Future<List<Song>> getSongs() async {
    return _localMusicService.getSongs();
  }

  Future<List<Song>> getTrending() async {
    return getSongs();
  }

  Future<List<Song>> getRecentlyPlayed() async {
    return getSongs();
  }

  Future<List<Song>> getNewReleases() async {
    return getSongs();
  }

  Future<List<dynamic>> getAlbums() async {
    return _localMusicService.getAlbums();
  }

  Future<List<dynamic>> getArtists() async {
    return _localMusicService.getArtists();
  }

  Future<List<dynamic>> getPlaylists() async {
    return _localMusicService.getPlaylists();
  }
}