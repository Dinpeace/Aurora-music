import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aurora_music/data/models/online/online_song.dart';
import 'package:aurora_music/features/player/player_controller.dart';
import 'package:aurora_music/features/library/favorite_provider.dart';

class FavoritePlaybackScreen extends ConsumerWidget {
  const FavoritePlaybackScreen({super.key});

  OnlineSong _toOnlineSong(FavoriteItem item) {
    return OnlineSong(
      id: item.id,
      title: item.title,
      artist: item.artist,
      album: item.album,
      artwork: item.artwork,
      streamUrl: item.streamUrl,
      duration: Duration(
        milliseconds: item.durationMs,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(favoriteProvider);
    final onlineFavorites =
        state.items.where((item) => item.isOnline).toList(growable: false);

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        title: const Text('Favorite Music'),
        backgroundColor: const Color(0xFF09090B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: state.loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : onlineFavorites.isEmpty
              ? const Center(
                  child: Text(
                    'No online favorites yet.',
                    style: TextStyle(color: Colors.white60),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  itemCount: onlineFavorites.length,
                  separatorBuilder: (_, index) => const Divider(
                    color: Color(0xFF27272A),
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final item = onlineFavorites[index];

                    return ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 4),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: item.artwork.isNotEmpty
                            ? Image.network(
                                item.artwork,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) =>
                                        _placeholder(),
                              )
                            : _placeholder(),
                      ),
                      title: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        item.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white60),
                      ),
                      trailing: const Icon(
                        Icons.play_circle_fill_rounded,
                        color: Color(0xFFA855F7),
                      ),
                      onTap: () {
                        final queue = onlineFavorites
                            .map(_toOnlineSong)
                            .toList(growable: false);

                        ref
                            .read(playerControllerProvider.notifier)
                            .playOnlineSong(
                              queue[index],
                              queue: queue,
                            );
                      },
                    );
                  },
                ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        gradient: LinearGradient(
          colors: [
            Color(0xFFA855F7),
            Color(0xFF22D3EE),
          ],
        ),
      ),
      child: const Icon(
        Icons.music_note_rounded,
        color: Colors.white,
      ),
    );
  }
}
