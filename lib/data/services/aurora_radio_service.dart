import '../models/listening_history_entry.dart';
import '../models/online/online_song.dart';
import 'adaptive_recommendation_service.dart';
import 'mood_energy_service.dart';
import 'smart_queue_service.dart';
import 'taste_profile_service.dart';

enum AuroraRadioMode { song, artist, mood, personalized }

class AuroraRadioService {
  AuroraRadioService({
    required AdaptiveRecommendationService adaptive,
    required SmartQueueService smartQueue,
    required MoodEnergyService mood,
  })  : _adaptive = adaptive,
        _smartQueue = smartQueue,
        _mood = mood;

  final AdaptiveRecommendationService _adaptive;
  final SmartQueueService _smartQueue;
  final MoodEnergyService _mood;

  List<OnlineSong> build({
    required Iterable<OnlineSong> candidates,
    required TasteProfile profile,
    required List<ListeningHistoryEntry> history,
    AuroraRadioMode mode = AuroraRadioMode.personalized,
    OnlineSong? seed,
    MoodProfile? mood,
    int length = 20,
  }) {
    if (length <= 0) return const <OnlineSong>[];

    final source = candidates.toList(growable: false);
    if (source.isEmpty) return const <OnlineSong>[];

    final activeMood = mood ?? _mood.inferCurrentProfile();
    final seedId = seed?.id.trim().toLowerCase();

    Iterable<OnlineSong> filtered = source;
    switch (mode) {
      case AuroraRadioMode.song:
        if (seed != null) {
          filtered = _songRadioCandidates(source, seed);
        }
        break;
      case AuroraRadioMode.artist:
        final seedArtist = seed?.artist.trim().toLowerCase();
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
    if (pool.length < length && mode == AuroraRadioMode.artist) {
      pool = source;
    }

    final excluded = <String>{};
    if (seedId != null && seedId.isNotEmpty) {
      excluded.add(seedId);
    }

    // Mood is used as a discovery pre-filter. Adaptive ranking then applies
    // the stronger long-term taste/history signals.
    final moodRanked = _mood.rank(
      pool,
      activeMood,
      excludedIds: excluded,
    );

    final moodPool = moodRanked.take(length * 3).toList(growable: false);

    final ranked = _adaptive.rank(
      candidates: moodPool.isEmpty ? pool : moodPool,
      profile: profile,
      history: history,
      excludedIds: excluded,
      limit: length * 2,
    );

    final continuation = _smartQueue.build(
      candidates: ranked,
      profile: profile,
      history: history,
      mood: activeMood,
      length: length,
    );

    if (seed == null) return continuation;

    return List<OnlineSong>.unmodifiable([
      seed,
      ...continuation.where(
        (song) => song.id.trim().toLowerCase() != seedId,
      ),
    ].take(length));
  }

  Iterable<OnlineSong> _songRadioCandidates(
    Iterable<OnlineSong> songs,
    OnlineSong seed,
  ) sync* {
    final seedArtist = seed.artist.trim().toLowerCase();
    final seedAlbum = seed.album.trim().toLowerCase();
    final seedId = seed.id.trim().toLowerCase();

    for (final song in songs) {
      final id = song.id.trim().toLowerCase();
      if (id == seedId) continue;

      final artist = song.artist.trim().toLowerCase();
      final album = song.album.trim().toLowerCase();
      if (artist == seedArtist || album == seedAlbum) yield song;
    }

    for (final song in songs) {
      if (song.id.trim().toLowerCase() != seedId) {
        yield song;
      }
    }
  }
}
