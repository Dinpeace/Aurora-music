import 'online/online_song.dart';

class SearchResult {
  final List<OnlineSong> songs;

  const SearchResult({
    required this.songs,
  });

  factory SearchResult.fromJson(
    Map<String, dynamic> json,
  ) {
    final items = json['songs'] as List? ?? [];

    return SearchResult(
      songs: items
          .map(
            (e) => OnlineSong.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}