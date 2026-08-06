import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../player_controller.dart';

class PlayerArtwork extends ConsumerWidget {
  const PlayerArtwork({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final song = ref.watch(playerControllerProvider).currentSong;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: AspectRatio(
        aspectRatio: 1,
        child: song != null && song.artwork.isNotEmpty
            ? Image.network(
                song.artwork,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFA855F7),
            Color(0xFF22D3EE),
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.music_note_rounded,
          size: 120,
          color: Colors.white,
        ),
      ),
    );
  }
}