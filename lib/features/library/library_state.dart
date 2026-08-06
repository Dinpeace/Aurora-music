import '../../data/models/song.dart';

class LibraryState {
  final bool loading;
  final bool permissionGranted;
  final List<Song> songs;

  const LibraryState({
    this.loading = false,
    this.permissionGranted = false,
    this.songs = const [],
  });

  LibraryState copyWith({
    bool? loading,
    bool? permissionGranted,
    List<Song>? songs,
  }) {
    return LibraryState(
      loading: loading ?? this.loading,
      permissionGranted:
          permissionGranted ?? this.permissionGranted,
      songs: songs ?? this.songs,
    );
  }
}