import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/song.dart';
import '../../shared/providers/repository_provider.dart';
import 'library_state.dart';

class LibraryController extends StateNotifier<LibraryState> {
  LibraryController(this.ref) : super(const LibraryState());

  final Ref ref;

  Future<void> loadLibrary() async {
    state = state.copyWith(loading: true);

    final repository = ref.read(musicRepositoryProvider);

    final granted = await repository.requestPermission();

    if (!granted) {
      state = state.copyWith(
        loading: false,
        permissionGranted: false,
      );
      return;
    }

    final songs = await repository.getSongs();

    state = state.copyWith(
      loading: false,
      permissionGranted: true,
      songs: songs,
    );
  }

  List<Song> get songs => state.songs;
}

final libraryControllerProvider =
    StateNotifierProvider<LibraryController, LibraryState>(
  (ref) => LibraryController(ref),
);