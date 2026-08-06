import '../models/song.dart';
import 'music_datasource.dart';

class FakeMusicDataSource implements MusicDataSource {
  @override
  Future<bool> requestPermission() async {
    return true;
  }

  @override
  Future<List<Song>> getSongs() async {
    return const [];
  }
}