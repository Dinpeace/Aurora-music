import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/repository_provider.dart';
import '../../../shared/widgets/music_card.dart';
import '../../../shared/widgets/section_title.dart';
import '../../player/player_controller.dart';

class TrendingSection extends ConsumerWidget {
  const TrendingSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(musicRepositoryProvider);
    final songs = repository.getTrending();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          title: 'Trending',
          onSeeAll: () {},
        ),

        const SizedBox(height: 16),

        SizedBox(
          height: 245,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: songs.length,
            separatorBuilder: (_, _) =>
                const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final song = songs[index];

              return MusicCard(
                title: song.title,
                artist: song.artist,
                image: song.artwork,
                isFavorite: song.favorite,
                onTap: () async {
                  await ref
                      .read(playerControllerProvider.notifier)
                      .playSong(
                        song,
                        queue: songs,
                      );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}