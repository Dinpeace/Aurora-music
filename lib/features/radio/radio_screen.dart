import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/online/online_song.dart';
import '../../data/models/song.dart';
import '../../data/services/aurora_radio_service.dart';
import '../../data/services/mood_energy_service.dart';
import '../../data/services/recommendation_engine.dart';
import '../../data/services/session_intelligence_service.dart';
import '../../data/services/smart_queue_service.dart';
import '../../data/services/taste_profile_service.dart';
import '../library/library_controller.dart';
import '../player/player_controller.dart';

class RadioScreen extends ConsumerStatefulWidget {
  const RadioScreen({
    super.key,
    this.mode = AuroraRadioMode.personalized,
    this.seed,
  });

  final AuroraRadioMode mode;
  final Song? seed;

  @override
  ConsumerState<RadioScreen> createState() => _RadioScreenState();
}

class _RadioScreenState extends ConsumerState<RadioScreen> {
  List<Song> _songs = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    final controller = ref.read(libraryControllerProvider.notifier);
    await controller.loadLibrary();

    if (!mounted) return;

    final library = ref.read(libraryControllerProvider);
    final songs = library.songs;

    final session = SessionIntelligenceService();
    final mood = MoodEnergyService(session: session);
    final taste = TasteProfileService();
    final recommendations = RecommendationEngine(
      taste: taste,
      mood: mood,
      session: session,
    );
    final queue = SmartQueueService(
      recommendations: recommendations,
      mood: mood,
    );
    final radio = AuroraRadioService(
      recommendations: recommendations,
      smartQueue: queue,
      mood: mood,
    );

    final favorites = songs.where((song) => song.favorite).toList();
    final profile = taste.build(
      history: const [],
      favoriteArtists: favorites.map((song) => song.artist).toList(),
      favoriteIds: favorites.map((song) => song.id).toList(),
    );

    final candidates = songs.map(_toOnlineSong).toList(growable: false);
    final seed = widget.seed == null ? null : _toOnlineSong(widget.seed!);

    final result = radio.build(
      candidates: candidates,
      profile: profile,
      mode: widget.mode,
      seed: seed,
      mood: mood.inferCurrentProfile(),
      length: 25,
    );

    final byId = <String, Song>{
      for (final song in songs) song.id: song,
    };

    setState(() {
      _songs = result
          .map((song) => byId[song.id])
          .whereType<Song>()
          .toList(growable: false);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (widget.mode) {
      AuroraRadioMode.song => 'Song Radio',
      AuroraRadioMode.artist => 'Artist Radio',
      AuroraRadioMode.mood => 'Mood Radio',
      AuroraRadioMode.personalized => 'Aurora Radio',
    };

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF09090B),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _songs.isEmpty
              ? const Center(
                  child: Text(
                    'Not enough music for this radio.',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  itemCount: _songs.length,
                  itemBuilder: (context, index) {
                    final song = _songs[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 52,
                          height: 52,
                          child: song.artwork == null || song.artwork!.isEmpty
                              ? const ColoredBox(
                                  color: Color(0xFF18181B),
                                  child: Icon(
                                    Icons.music_note,
                                    color: Colors.white54,
                                  ),
                                )
                              : Image(
                                  image: _artwork(song.artwork!),
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                      title: Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        song.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white60),
                      ),
                      onTap: () {
                        ref
                            .read(playerControllerProvider.notifier)
                            .playSong(song, queue: _songs);
                      },
                    );
                  },
                ),
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

  ImageProvider<Object> _artwork(String value) {
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return NetworkImage(value);
    }
    return AssetImage(value);
  }
}
