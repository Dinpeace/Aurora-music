import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

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
    final controller = ref.read(playerControllerProvider.notifier);
    final song = player.currentSong;

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: SafeArea(
        child: song == null
            ? const _NothingPlaying()
            : _NowPlayingContent(
                title: song.title,
                artist: song.artist,
                youtubeController: controller.usesYoutubePlayer
                    ? controller.youtubeController
                    : null,
              ),
      ),
    );
  }
}

class _NothingPlaying extends StatelessWidget {
  const _NothingPlaying();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const PlayerHeader(),
        const Expanded(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.music_note_rounded,
                    size: 90,
                    color: Colors.white24,
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Nothing Playing',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Choose a song from Search or your Library.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 15),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NowPlayingContent extends StatelessWidget {
  const _NowPlayingContent({
    required this.title,
    required this.artist,
    this.youtubeController,
  });

  final String title;
  final String artist;
  final YoutubePlayerController? youtubeController;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final artworkSize = (constraints.maxWidth - 48).clamp(220.0, 380.0);

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 16),
            child: Column(
              children: [
                const PlayerHeader(),

                const SizedBox(height: 28),

                if (youtubeController != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: YoutubePlayer(
                      controller: youtubeController!,
                      aspectRatio: 16 / 9,
                    ),
                  ),
                  const SizedBox(height: 28),
                ],

                SizedBox(
                  width: artworkSize,
                  height: artworkSize,
                  child: const PlayerArtwork(),
                ),

                const SizedBox(height: 28),

                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  artist,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white60, fontSize: 17),
                ),

                const SizedBox(height: 28),

                const PlayerProgress(),

                const SizedBox(height: 24),

                const PlayerButtons(),
              ],
            ),
          ),
        );
      },
    );
  }
}
