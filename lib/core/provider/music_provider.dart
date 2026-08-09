import '../../data/models/online/online_song.dart';

abstract class MusicProvider {
  Future<List<OnlineSong>> search(
    String query,
  );

  Future<List<OnlineSong>> trending();

  Future<List<OnlineSong>> recommendations();

  Future<String> streamUrl(
    String songId,
  );

  Future<String?> lyrics(
    String songId,
  );
}