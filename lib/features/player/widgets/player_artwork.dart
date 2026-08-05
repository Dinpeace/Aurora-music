import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../player_controller.dart';

class PlayerArtwork extends ConsumerWidget {
  const PlayerArtwork({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final song = ref.watch(playerControllerProvider).currentSong;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AspectRatio(
        aspectRatio: 1,
        child: song == null
            ? Container(
                color: Colors.grey.shade900,
                child: const Icon(
                  Icons.music_note,
                  size: 100,
                  color: Colors.white54,
                ),
              )
            : Image.network(
                song.artwork,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: Colors.grey.shade900,
                  child: const Icon(
                    Icons.music_note,
                    color: Colors.white54,
                    size: 100,
                  ),
                ),
              ),
      ),
    );
  }
}