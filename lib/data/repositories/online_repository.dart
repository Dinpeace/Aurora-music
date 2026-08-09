import '../datasources/online/models/stream_response.dart';
import '../datasources/online/music_provider.dart';
import '../models/online/online_song.dart';

class OnlineRepository {
  final MusicProvider provider;

  const OnlineRepository({
    required this.provider,
  });

  Future<List<OnlineSong>> search(String query) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) return const [];

    final result = await provider.search(normalizedQuery);
    return result.songs;
  }

  Future<List<OnlineSong>> trending() {
    return provider.getTrending();
  }

  Future<StreamResponse> getStream(String songId) {
    return provider.getStream(songId);
  }
}
