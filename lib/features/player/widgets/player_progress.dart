import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../player_controller.dart';

class PlayerProgress extends ConsumerWidget {
  const PlayerProgress({super.key});

  String format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerControllerProvider);

    return Column(
      children: [
        Slider(
          value: player.position.inSeconds.toDouble(),
          max: player.duration.inSeconds == 0
              ? 1
              : player.duration.inSeconds.toDouble(),
          onChanged: (value) {
            ref
                .read(playerControllerProvider.notifier)
                .seek(Duration(seconds: value.toInt()));
          },
        ),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              format(player.position),
              style: const TextStyle(color: Colors.white70),
            ),
            Text(
              format(player.duration),
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ],
    );
  }
}