import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/music_card.dart';
import '../../library/library_controller.dart';
import '../../player/player_controller.dart';

class RecentlyPlayed extends ConsumerWidget {
  const RecentlyPlayed({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(libraryControllerProvider);

    if (library.loading) {
      return const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (library.songs.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(
          child: Text(
            'Nothing played yet',
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
            heroTag: 'recently-played-${song.id}',
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
