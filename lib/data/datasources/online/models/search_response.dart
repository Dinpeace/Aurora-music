import '../../../models/online/online_song.dart';

class SearchResponse {
  final List<OnlineSong> songs;

  const SearchResponse({
    required this.songs,
  });

  factory SearchResponse.empty() {
    return const SearchResponse(
      songs: [],
    );
  }
}