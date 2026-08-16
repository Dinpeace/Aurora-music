import '../models/online/online_song.dart';
import 'session_intelligence_service.dart';

/// Lightweight mood and energy intelligence for online discovery.
///
/// Aurora does not currently receive acoustic features from the online
/// provider, so mood/energy is inferred from metadata, time of day, and the
/// active listening session. The service is deterministic and safe to use
/// offline; it never blocks playback.
class MoodEnergyService {
  MoodEnergyService({
    required SessionIntelligenceService session,
  }) : _session = session;

  final SessionIntelligenceService _session;

  List<MoodProfile> get profiles => const [
        MoodProfile.chill,
        MoodProfile.focus,
        MoodProfile.happy,
        MoodProfile.sad,
        MoodProfile.energetic,
        MoodProfile.night,
      ];

  MoodProfile inferCurrentProfile() {
    final hour = DateTime.now().hour;

    if (hour >= 22 || hour < 6) {
      return MoodProfile.night;
    }

    if (hour >= 6 && hour < 11) {
      return MoodProfile.happy;
    }

    if (_session.playedCount > 0 &&
        _session.skippedCount > _session.playedCount ~/ 2) {
      return MoodProfile.energetic;
    }

    return MoodProfile.chill;
  }

  MoodMatch analyze(
    OnlineSong song,
    MoodProfile profile,
  ) {
    final text = '${song.title} ${song.artist} ${song.album}'.toLowerCase();
    final keywords = profile.keywords;

    var keywordHits = 0;
    for (final keyword in keywords) {
      if (text.contains(keyword)) {
        keywordHits++;
      }
    }

    var energy = _baseEnergy(song);
    var moodScore = keywordHits * 4.0;

    if (profile == MoodProfile.night &&
        (text.contains('night') ||
            text.contains('midnight') ||
            text.contains('late night'))) {
      moodScore += 3.0;
      energy -= 0.15;
    }

    if (profile == MoodProfile.energetic &&
        (text.contains('remix') ||
            text.contains('dance') ||
            text.contains('party') ||
            text.contains('live'))) {
      moodScore += 2.5;
      energy += 0.2;
    }

    final artist = song.artist.trim().toLowerCase();
    final artistPlays = _session.artistPlayCounts[artist] ?? 0;
    moodScore += artistPlays.clamp(0, 8) * 0.75;

    return MoodMatch(
      mood: profile,
      score: moodScore,
      energy: energy.clamp(0.0, 1.0).toDouble(),
    );
  }

  List<OnlineSong> rank(
    Iterable<OnlineSong> songs,
    MoodProfile profile, {
    Set<String> excludedIds = const <String>{},
  }) {
    final excluded = excludedIds.map((id) => id.trim()).toSet();
    final scored = <_MoodCandidate>[];

    for (final song in songs) {
      if (song.id.trim().isEmpty || excluded.contains(song.id)) {
        continue;
      }

      final match = analyze(song, profile);
      scored.add(_MoodCandidate(song: song, match: match));
    }

    scored.sort((a, b) {
      final score = b.match.score.compareTo(a.match.score);
      if (score != 0) return score;

      final energy = b.match.energy.compareTo(a.match.energy);
      if (energy != 0) return energy;

      return a.song.title.toLowerCase().compareTo(
            b.song.title.toLowerCase(),
          );
    });

    return scored.map((item) => item.song).toList(growable: false);
  }

  double _baseEnergy(OnlineSong song) {
    final text = '${song.title} ${song.album}'.toLowerCase();
    var energy = 0.5;

    const highEnergy = [
      'remix',
      'dance',
      'party',
      'workout',
      'rock',
      'edm',
      'club',
      'bass',
      'festival',
      'upbeat',
    ];

    const lowEnergy = [
      'acoustic',
      'piano',
      'sleep',
      'chill',
      'lofi',
      'ambient',
      'calm',
      'slow',
      'sad',
      'night',
    ];

    for (final word in highEnergy) {
      if (text.contains(word)) energy += 0.08;
    }

    for (final word in lowEnergy) {
      if (text.contains(word)) energy -= 0.06;
    }

    return energy.clamp(0.0, 1.0).toDouble();
  }
}

enum MoodProfile {
  chill,
  focus,
  happy,
  sad,
  energetic,
  night,
}

extension MoodProfileDetails on MoodProfile {
  String get title {
    switch (this) {
      case MoodProfile.chill:
        return 'Chill';
      case MoodProfile.focus:
        return 'Focus';
      case MoodProfile.happy:
        return 'Happy';
      case MoodProfile.sad:
        return 'Melancholy';
      case MoodProfile.energetic:
        return 'High Energy';
      case MoodProfile.night:
        return 'Night';
    }
  }

  String get subtitle {
    switch (this) {
      case MoodProfile.chill:
        return 'Easygoing sounds';
      case MoodProfile.focus:
        return 'Stay in the zone';
      case MoodProfile.happy:
        return 'Bright and uplifting';
      case MoodProfile.sad:
        return 'Soft and reflective';
      case MoodProfile.energetic:
        return 'Turn it up';
      case MoodProfile.night:
        return 'Late-night atmosphere';
    }
  }

  List<String> get keywords {
    switch (this) {
      case MoodProfile.chill:
        return const ['chill', 'lofi', 'acoustic', 'calm', 'relax', 'vibe'];
      case MoodProfile.focus:
        return const ['focus', 'instrumental', 'ambient', 'study', 'piano'];
      case MoodProfile.happy:
        return const ['happy', 'feel good', 'sunshine', 'summer', 'upbeat'];
      case MoodProfile.sad:
        return const ['sad', 'melancholy', 'heartbreak', 'emotional', 'slow'];
      case MoodProfile.energetic:
        return const ['dance', 'party', 'workout', 'remix', 'rock', 'edm'];
      case MoodProfile.night:
        return const ['night', 'midnight', 'late night', 'chill', 'sleep'];
    }
  }

  String get iconLabel {
    switch (this) {
      case MoodProfile.chill:
        return '☁';
      case MoodProfile.focus:
        return '◉';
      case MoodProfile.happy:
        return '✦';
      case MoodProfile.sad:
        return '◌';
      case MoodProfile.energetic:
        return '⚡';
      case MoodProfile.night:
        return '☾';
    }
  }
}

class MoodMatch {
  const MoodMatch({
    required this.mood,
    required this.score,
    required this.energy,
  });

  final MoodProfile mood;
  final double score;
  final double energy;
}

class _MoodCandidate {
  const _MoodCandidate({
    required this.song,
    required this.match,
  });

  final OnlineSong song;
  final MoodMatch match;
}
