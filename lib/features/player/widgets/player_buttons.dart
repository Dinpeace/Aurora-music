import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../player_controller.dart';
import '../player_state.dart';

class PlayerButtons extends ConsumerWidget {
  const PlayerButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerControllerProvider);
    final controller =
        ref.read(playerControllerProvider.notifier);

    final hasSong = player.currentSong != null;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _SmallControl(
              icon: Icons.shuffle_rounded,
              active: player.isShuffleEnabled,
              enabled: hasSong,
              onPressed: controller.toggleShuffle,
            ),

            _SmallControl(
              icon: Icons.skip_previous_rounded,
              size: 34,
              enabled: hasSong,
              onPressed: controller.previousSong,
            ),

            _PlayPauseButton(
              playing: player.isPlaying,
              enabled: hasSong,
              onPressed: controller.togglePlayPause,
            ),

            _SmallControl(
              icon: Icons.skip_next_rounded,
              size: 34,
              enabled: hasSong,
              onPressed: controller.nextSong,
            ),

            _SmallControl(
              icon: player.repeatMode == PlayerRepeatMode.one
                  ? Icons.repeat_one_rounded
                  : Icons.repeat_rounded,
              active: player.repeatMode != PlayerRepeatMode.off,
              enabled: hasSong,
              onPressed: controller.cycleRepeatMode,
            ),
          ],
        ),

        const SizedBox(height: 24),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SecondaryButton(
              icon: Icons.favorite_border_rounded,
              label: 'Favorite',
              enabled: hasSong,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Favorite controls will be connected next.',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            _SecondaryButton(
              icon: Icons.queue_music_rounded,
              label: 'Queue',
              enabled: hasSong,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Queue controls will be connected next.',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  const _PlayPauseButton({
    required this.playing,
    required this.enabled,
    required this.onPressed,
  });

  final bool playing;
  final bool enabled;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      height: 76,
      child: Material(
        color: enabled
            ? const Color(0xFFA855F7)
            : Colors.white12,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? onPressed : null,
          child: Icon(
            playing
                ? Icons.pause_rounded
                : Icons.play_arrow_rounded,
            color: enabled
                ? Colors.white
                : Colors.white30,
            size: 40,
          ),
        ),
      ),
    );
  }
}

class _SmallControl extends StatelessWidget {
  const _SmallControl({
    required this.icon,
    required this.enabled,
    required this.onPressed,
    this.active = false,
    this.size = 25,
  });

  final IconData icon;
  final bool enabled;
  final bool active;
  final double size;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: enabled ? onPressed : null,
      icon: Icon(
        icon,
        size: size,
        color: !enabled
            ? Colors.white24
            : active
                ? const Color(0xFFA855F7)
                : Colors.white,
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 19),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor:
            enabled ? Colors.white70 : Colors.white24,
        side: BorderSide(
          color:
              enabled ? Colors.white12 : Colors.white10,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 11,
        ),
      ),
    );
  }
}