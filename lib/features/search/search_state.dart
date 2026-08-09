import '../../data/models/online/online_song.dart';

class SearchState {
  final bool loading;
  final String query;
  final List<OnlineSong> songs;
  final String? error;

  const SearchState({
    this.loading = false,
    this.query = '',
    this.songs = const [],
    this.error,
  });

  SearchState copyWith({
    bool? loading,
    String? query,
    List<OnlineSong>? songs,
    String? error,
    bool clearError = false,
  }) {
    return SearchState(
      loading: loading ?? this.loading,
      query: query ?? this.query,
      songs: songs ?? this.songs,
      error: clearError ? null : error ?? this.error,
    );
  }
}
