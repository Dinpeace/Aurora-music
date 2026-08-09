import '../../core/platform/media_channel.dart';
import '../models/song.dart';

class LocalMusicService {
  const LocalMusicService();

  Future<bool> requestPermission() {
    return MediaChannel.requestPermission();
  }

  Future<List<Song>> getSongs() async {
    final rawSongs = await MediaChannel.getSongs();

    return rawSongs.map((song) {
      return Song(
        id: song['id'].toString(),
        title: (song['title'] ?? 'Unknown Title') as String,
        artist: (song['artist'] ?? 'Unknown Artist') as String,
        album: (song['album'] ?? 'Unknown Album') as String,
        artwork: song['artwork'] as String?,
        audioUrl: (song['path'] ?? '') as String,
        duration: Duration(
          milliseconds: (song['duration'] ?? 0) as int,
        ),
      );
    }).toList();
  }
}