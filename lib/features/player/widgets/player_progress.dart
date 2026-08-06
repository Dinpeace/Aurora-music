import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../player_controller.dart';

class PlayerProgress extends ConsumerWidget {
  const PlayerProgress({super.key});

  String _format(Duration duration) {
    final minutes =
        duration.inMinutes.remainder(60).toString().padLeft(2, '0');

    final seconds =
        duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerControllerProvider);

    final currentSong = player.currentSong;

    final totalDuration =
        currentSong?.duration ?? Duration.zero;

    final position = player.position;

    return Column(
      children: [
        Slider(
          value: position.inMilliseconds
              .clamp(
                0,
                totalDuration.inMilliseconds,
              )
              .toDouble(),
          max: totalDuration.inMilliseconds == 0
              ? 1
              : totalDuration.inMilliseconds.toDouble(),
          onChanged: (value) {
            ref
                .read(playerControllerProvider.notifier)
                .seek(
                  Duration(
                    milliseconds: value.toInt(),
                  ),
                );
          },
        ),

        Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _format(position),
              style: const TextStyle(
                color: Colors.white70,
              ),
            ),
            Text(
              _format(totalDuration),
              style: const TextStyle(
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ],
    );
  }
}