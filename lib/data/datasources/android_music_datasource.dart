import '../../core/platform/media_channel.dart';
import '../models/song.dart';
import 'music_datasource.dart';

class AndroidMusicDataSource implements MusicDataSource {
  @override
  Future<bool> requestPermission() {
    return MediaChannel.requestPermission();
  }

  @override
  Future<List<Song>> getSongs() async {
    final rawSongs = await MediaChannel.getSongs();

    return rawSongs.map((song) {
      return Song(
        id: song['id'].toString(),
        title: song['title'] as String? ?? 'Unknown Title',
        artist: song['artist'] as String? ?? 'Unknown Artist',
        album: song['album'] as String? ?? 'Unknown Album',
        artwork: song['artwork'] as String? ?? '',
        audioUrl: song['path'] as String? ?? '',
        duration: Duration(
          milliseconds: song['duration'] as int? ?? 0,
        ),
      );
    }).toList();
  }
}