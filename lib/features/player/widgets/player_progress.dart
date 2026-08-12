import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../player_controller.dart';

class PlayerProgress extends ConsumerWidget {
  const PlayerProgress({super.key});

  String _format(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    return '$minutes:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerControllerProvider);
    final controller =
        ref.read(playerControllerProvider.notifier);

    final duration = player.duration;
    final position = player.position;

    final maxMilliseconds =
        duration.inMilliseconds > 0
            ? duration.inMilliseconds
            : 1;

    final currentMilliseconds = position.inMilliseconds.clamp(
      0,
      maxMilliseconds,
    );

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            activeTrackColor: const Color(0xFFA855F7),
            inactiveTrackColor: Colors.white12,
            thumbColor: Colors.white,
            overlayColor: const Color(0x33A855F7),
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 6,
            ),
            overlayShape: const RoundSliderOverlayShape(
              overlayRadius: 16,
            ),
          ),
          child: Slider(
            value: currentMilliseconds.toDouble(),
            max: maxMilliseconds.toDouble(),
            onChanged: duration <= Duration.zero
                ? null
                : (value) {
                    controller.seek(
                      Duration(
                        milliseconds: value.round(),
                      ),
                    );
                  },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 4,
          ),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _format(position),
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
              Text(
                _format(duration),
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
