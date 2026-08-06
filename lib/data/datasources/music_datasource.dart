import '../models/song.dart';

abstract class MusicDataSource {
  Future<bool> requestPermission();

  Future<List<Song>> getSongs();
}