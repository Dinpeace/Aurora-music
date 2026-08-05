import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'player_controller.dart';
import 'widgets/player_artwork.dart';
import 'widgets/player_buttons.dart';
import 'widgets/player_header.dart';
import 'widgets/player_progress.dart';

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerControllerProvider);
    final song = state.currentSong;

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: SafeArea(
        child: song == null
            ? const Center(
                child: Text(
                  'No song selected',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const PlayerHeader(),

                    const SizedBox(height: 24),

                    const PlayerArtwork(),

                    const SizedBox(height: 24),

                    Text(
                      song.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      song.artist,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                      ),
                    ),

                    const SizedBox(height: 32),

                    const PlayerProgress(),

                    const SizedBox(height: 24),

                    const PlayerButtons(),
                  ],
                ),
              ),
      ),
    );
  }
}