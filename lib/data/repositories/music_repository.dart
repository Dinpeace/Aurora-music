import '../models/song.dart';
import '../services/local_music_service.dart';

class MusicRepository {
  MusicRepository({
    LocalMusicService? localMusicService,
  }) : _localMusicService =
            localMusicService ?? const LocalMusicService();

  final LocalMusicService _localMusicService;

  Future<bool> requestPermission() {
    return _localMusicService.requestPermission();
  }

  Future<List<Song>> getSongs() {
    return _localMusicService.getSongs();
  }

  Future<List<Song>> getTrending() {
    return getSongs();
  }

  Future<List<Song>> getRecentlyPlayed() {
    return getSongs();
  }

  Future<List<Song>> getNewReleases() {
    return getSongs();
  }
}