import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../player/player_controller.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerControllerProvider);
    final song = player.currentSong;

    return Material(
      color: const Color(0xFF18181B),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/player');
        },
        child: SafeArea(
          top: false,
          child: Container(
            height: 74,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: song != null && song.artwork.isNotEmpty
                      ? Image.network(
                          song.artwork,
                          width: 58,
                          height: 58,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              _placeholderArtwork(),
                        )
                      : _placeholderArtwork(),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song?.title ?? "Nothing Playing",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        song?.artist ?? "Aurora Music",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                IconButton(
                  onPressed: () {
                    ref
                        .read(playerControllerProvider.notifier)
                        .togglePlayPause();
                  },
                  icon: Icon(
                    player.isPlaying
                        ? Icons.pause_circle_filled_rounded
                        : Icons.play_circle_fill_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholderArtwork() {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
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