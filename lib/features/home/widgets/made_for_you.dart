import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/online/online_song.dart';
import '../../../data/models/song.dart';
import '../../../data/services/adaptive_recommendation_service.dart';
import '../../../data/services/listening_history_service.dart';
import '../../../data/services/taste_profile_service.dart';
import '../../../shared/widgets/music_card.dart';
import '../../library/library_controller.dart';
import '../../player/player_controller.dart';

class MadeForYouSection extends ConsumerStatefulWidget {
  const MadeForYouSection({super.key});

  @override
  ConsumerState<MadeForYouSection> createState() => _MadeForYouSectionState();
}

class _MadeForYouSectionState extends ConsumerState<MadeForYouSection> {
  final ListeningHistoryService _history = ListeningHistoryService();
  final AdaptiveRecommendationService _adaptive =
      AdaptiveRecommendationService();

  List<OnlineSong> _recommendations = const [];
  bool _loading = true;
  String _signature = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(_refresh);
  }

  Future<void> _refresh() async {
    final library = ref.read(libraryControllerProvider);
    if (library.loading ||
        !library.permissionGranted ||
        library.songs.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    await _history.initialize();
    if (!mounted) return;

    final songs = library.songs;
    final favorites = songs.where((song) => song.favorite).toList();
    final history = _history.entries;

    final signature = [
      songs.length,
      favorites.length,
      history.length,
      ...history.take(5).map(
            (entry) =>
                '${entry.song.id}:${entry.playCount}:${entry.skipCount}:${entry.lastPlayed.millisecondsSinceEpoch}',
          ),
    ].join('|');

    if (signature == _signature && !_loading) return;
    _signature = signature;

    final taste = TasteProfileService();

    final profile = taste.build(
      history: history,
      favoriteArtists: favorites.map((song) => song.artist).toList(),
      favoriteIds: favorites.map((song) => song.id).toList(),
    );

    final recommendations = _adaptive.rank(
      candidates: songs.map(_toOnlineSong).toList(growable: false),
      profile: profile,
      history: history,
      limit: 10,
    );

    if (!mounted) return;
    setState(() {
      _recommendations = recommendations;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(libraryControllerProvider);

    if (library.loading ||
        !library.permissionGranted ||
        library.songs.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_loading) {
      return const SizedBox(
        height: 250,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    final byId = <String, Song>{
      for (final song in library.songs) song.id: song,
    };

    final songs = _recommendations
        .map((song) => byId[song.id])
        .whereType<Song>()
        .toList(growable: false);

    if (songs.isEmpty) return const SizedBox.shrink();

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
            itemCount: songs.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final song = songs[index];

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
                      .playSong(song, queue: songs);
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
