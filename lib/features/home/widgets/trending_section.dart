import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/music_card.dart';
import '../../library/library_controller.dart';
import '../../player/player_controller.dart';

class TrendingSection extends ConsumerStatefulWidget {
  const TrendingSection({super.key});

  @override
  ConsumerState<TrendingSection> createState() => _TrendingSectionState();
}

class _TrendingSectionState extends ConsumerState<TrendingSection> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(libraryControllerProvider.notifier).loadLibrary();
    });
  }

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(libraryControllerProvider);

    if (library.loading) {
      return const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (!library.permissionGranted) {
      return const SizedBox(
        height: 220,
        child: Center(
          child: Text(
            'Storage permission required',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    if (library.songs.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(
          child: Text(
            'No music found',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return SizedBox(
      height: 250,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: library.songs.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final song = library.songs[index];

          return MusicCard(
            title: song.title,
            artist: song.artist,
            image: song.artwork ?? '',
            heroTag: 'trending-${song.id}',
            favoriteId: song.id,
            favoriteAlbum: song.album,
            favoriteStreamUrl: song.audioUrl,
            favoriteDuration: song.duration,
            favoriteIsOnline: false,
            onTap: () {
              ref
                  .read(playerControllerProvider.notifier)
                  .playSong(song, queue: library.songs);
            },
          );
        },
      ),
    );
  }
}
