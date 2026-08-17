import '../models/online/online_song.dart';
import 'mood_energy_service.dart';
import 'recommendation_engine.dart';
import 'smart_queue_service.dart';
import 'taste_profile_service.dart';

enum AuroraRadioMode {
  song,
  artist,
  mood,
  personalized,
}

/// Creates an Aurora radio queue from the recommendation and smart-queue
/// layers. It deliberately does not start playback or mutate player state.
class AuroraRadioService {
  AuroraRadioService({
    required RecommendationEngine recommendations,
    required SmartQueueService smartQueue,
    required MoodEnergyService mood,
  })  : _recommendations = recommendations,
        _smartQueue = smartQueue,
        _mood = mood;

  final RecommendationEngine _recommendations;
  final SmartQueueService _smartQueue;
  final MoodEnergyService _mood;

  List<OnlineSong> build({
    required Iterable<OnlineSong> candidates,
    required TasteProfile profile,
    AuroraRadioMode mode = AuroraRadioMode.personalized,
    OnlineSong? seed,
    MoodProfile? mood,
    int length = 20,
  }) {
    if (length <= 0) return const <OnlineSong>[];

    final source = candidates.toList(growable: false);
    if (source.isEmpty) return const <OnlineSong>[];

    final selectedMood = mood ?? _mood.inferCurrentProfile();
    final seedArtist = seed?.artist.trim().toLowerCase();

    Iterable<OnlineSong> filtered = source;

    switch (mode) {
      case AuroraRadioMode.song:
        if (seed != null) {
          filtered = _songRadioCandidates(source, seed);
        }
        break;
      case AuroraRadioMode.artist:
        if (seedArtist != null && seedArtist.isNotEmpty) {
          filtered = source.where(
            (song) => song.artist.trim().toLowerCase() == seedArtist,
          );
        }
        break;
      case AuroraRadioMode.mood:
      case AuroraRadioMode.personalized:
        break;
    }

    var pool = filtered.toList(growable: false);

    // If a strict artist radio has too few candidates, fall back to the full
    // catalog rather than returning an unexpectedly tiny queue.
    if (pool.length < length && mode == AuroraRadioMode.artist) {
      pool = source;
    }

    final ranked = _recommendations.rank(
      candidates: pool,
      profile: profile,
      mood: selectedMood,
      excludedIds: seed == null ? const <String>{} : {seed.id},
      limit: length * 2,
    );

    final continuation = _smartQueue.build(
      candidates: ranked,
      profile: profile,
      mood: selectedMood,
      length: length,
    );

    if (seed == null) {
      return continuation;
    }

    return List<OnlineSong>.unmodifiable([
      seed,
      ...continuation.where(
        (song) => song.id.trim().toLowerCase() != seed.id.trim().toLowerCase(),
      ),
    ].take(length));
  }

  Iterable<OnlineSong> _songRadioCandidates(
    Iterable<OnlineSong> songs,
    OnlineSong seed,
  ) sync* {
    final seedArtist = seed.artist.trim().toLowerCase();
    final seedAlbum = seed.album.trim().toLowerCase();

    for (final song in songs) {
      final artist = song.artist.trim().toLowerCase();
      final album = song.album.trim().toLowerCase();

      if (song.id.trim().toLowerCase() == seed.id.trim().toLowerCase()) {
        continue;
      }

      // Favor the seed's artist/album, while still allowing discovery from
      // the wider catalog.
      if (artist == seedArtist || album == seedAlbum) {
        yield song;
      }
    }

    for (final song in songs) {
      final id = song.id.trim().toLowerCase();
      if (id == seed.id.trim().toLowerCase()) continue;
      yield song;
    }
  }
}
