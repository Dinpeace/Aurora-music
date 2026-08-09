import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/artwork_widget.dart';
import '../../player/player_controller.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerControllerProvider);
    final song = player.currentSong;

    return Material(
      color: const Color(0xFF18181B),
      elevation: 8,
      child: InkWell(
        onTap: () {
          context.push('/player');
        },
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 88,
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: player.progress,
                  minHeight: 2,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation(
                    Color(0xFFA855F7),
                  ),
                ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        ArtworkWidget(
                          artwork: song?.artwork,
                          width: 56,
                          height: 56,
                          borderRadius:
                              BorderRadius.circular(12),
                        ),

                        const SizedBox(width: 14),

                        Expanded(
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                song?.title ??
                                    'Nothing Playing',
                                maxLines: 1,
                                overflow:
                                    TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                song?.artist ??
                                    'Aurora Music',
                                maxLines: 1,
                                overflow:
                                    TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 13,
                                ),
                              ),

                              const SizedBox(height: 6),

                              Text(
                                '${player.positionText} / ${player.durationText}',
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),

                        IconButton(
                          onPressed: () {
                            ref
                                .read(
                                  playerControllerProvider
                                      .notifier,
                                )
                                .togglePlayPause();
                          },
                          icon: Icon(
                            player.isPlaying
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_fill,
                            size: 38,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}