import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../player_controller.dart';
import '../player_state.dart';

class PlayerButtons extends ConsumerWidget {
  const PlayerButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerControllerProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          onPressed: () {
            ref
                .read(playerControllerProvider.notifier)
                .toggleShuffle();
          },
          icon: Icon(
            Icons.shuffle,
            color: player.isShuffleEnabled
                ? const Color(0xFFA855F7)
                : Colors.white,
          ),
        ),

        IconButton(
          onPressed: () {
            ref
                .read(playerControllerProvider.notifier)
                .previousSong();
          },
          icon: const Icon(
            Icons.skip_previous_rounded,
            size: 40,
            color: Colors.white,
          ),
        ),

        Container(
          width: 70,
          height: 70,
          decoration: const BoxDecoration(
            color: Color(0xFFA855F7),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: () {
              ref
                  .read(playerControllerProvider.notifier)
                  .togglePlayPause();
            },
            icon: Icon(
              player.isPlaying
                  ? Icons.pause
                  : Icons.play_arrow,
              color: Colors.white,
              size: 36,
            ),
          ),
        ),

        IconButton(
          onPressed: () {
            ref
                .read(playerControllerProvider.notifier)
                .nextSong();
          },
          icon: const Icon(
            Icons.skip_next_rounded,
            size: 40,
            color: Colors.white,
          ),
        ),

        IconButton(
          onPressed: () {
            ref
                .read(playerControllerProvider.notifier)
                .cycleRepeatMode();
          },
          icon: Icon(
            player.repeatMode == PlayerRepeatMode.one
                ? Icons.repeat_one
                : Icons.repeat,
            color: player.repeatMode == PlayerRepeatMode.off
                ? Colors.white
                : const Color(0xFFA855F7),
          ),
        ),
      ],
    );
  }
}