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
    final player = ref.watch(playerControllerProvider);
    final song = player.currentSong;

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: SafeArea(
        child: song == null
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.music_note_rounded,
                      size: 90,
                      color: Colors.white38,
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Nothing Playing",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Select a song from your library",
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const PlayerHeader(),

                    const SizedBox(height: 24),

                    const PlayerArtwork(),

                    const SizedBox(height: 32),

                    Text(
                      song.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      song.artist,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                      ),
                    ),

                    const SizedBox(height: 32),

                    const PlayerProgress(),

                    const SizedBox(height: 32),

                    const PlayerButtons(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }
}