import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/online/online_song.dart';
import '../../../data/models/song.dart';
import '../../../data/services/mood_energy_service.dart';
import '../../../data/services/recommendation_engine.dart';
import '../../../data/services/session_intelligence_service.dart';
import '../../../data/services/taste_profile_service.dart';
import '../../../shared/widgets/music_card.dart';
import '../../library/library_controller.dart';
import '../../player/player_controller.dart';

class MadeForYouSection extends ConsumerWidget {
  const MadeForYouSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(libraryControllerProvider);

    if (library.loading || !library.permissionGranted || library.songs.isEmpty) {
      return const SizedBox.shrink();
    }

    final songs = library.songs;
    final favoriteSongs = songs.where((song) => song.favorite).toList();

    final profile = TasteProfileService().build(
      history: const [],
      favoriteArtists: favoriteSongs.map((song) => song.artist).toList(),
      favoriteIds: favoriteSongs.map((song) => song.id).toList(),
    );

    final session = SessionIntelligenceService();
    final mood = MoodEnergyService(session: session);
    final engine = RecommendationEngine(
      taste: TasteProfileService(),
      mood: mood,
      session: session,
    );

    final candidates = songs.map(_toOnlineSong).toList(growable: false);
    final recommendations = engine.rank(
      candidates: candidates,
      profile: profile,
      mood: mood.inferCurrentProfile(),
      limit: 10,
    );

    if (recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    final byId = <String, Song>{
      for (final song in songs) song.id: song,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Made For You',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 250,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: recommendations.length,
            separatorBuilder: (_, _) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final onlineSong = recommendations[index];
              final song = byId[onlineSong.id];
              if (song == null) return const SizedBox.shrink();

              return MusicCard(
                title: song.title,
                artist: song.artist,
                image: song.artwork ?? '',
                favoriteId: song.id,
                favoriteAlbum: song.album,
                favoriteStreamUrl: song.audioUrl,
                favoriteDuration: song.duration,
                favoriteIsOnline: false,
                onTap: () {
                  ref
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

  OnlineSong _toOnlineSong(Song song) {
    return OnlineSong(
      id: song.id,
      title: song.title,
      artist: song.artist,
      album: song.album,
      artwork: song.artwork ?? '',
      streamUrl: song.audioUrl,
      duration: song.duration,
    );
  }
}
