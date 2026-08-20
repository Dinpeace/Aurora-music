import 'dart:math' as math;

import 'smart_queue_service.dart';

/// Aurora Smart Queue v20-v40 compatibility layer.
///
/// This file is additive: it does not replace SmartQueueService or any
/// v1-v19 service. Existing v1-v19 code can continue using its current APIs.
///
/// v20-v40 are exposed as small, deterministic services so each milestone
/// can be adopted independently and tested before wiring it into production.
enum AuroraMode { balanced, focus, chill, discovery, favorites }

enum AuroraSessionState {
  start,
  exploring,
  engaged,
  deepListening,
  fatigued,
  discovery,
  reset,
}

enum AuroraFeedbackType {
  moreLikeThis,
  lessLikeThis,
  moreDiscovery,
  moreFamiliar,
  keepMood,
  changeMood,
}

class AuroraSessionSnapshot {
  const AuroraSessionSnapshot({
    this.plays = 0,
    this.skips = 0,
    this.completions = 0,
    this.favorites = 0,
    this.repeats = 0,
    this.minutes = 0,
  });

  final int plays;
  final int skips;
  final int completions;
  final int favorites;
  final int repeats;
  final int minutes;

  double get skipRate => plays == 0 ? 0 : _clamp(skips / plays);
  double get completionRate => plays == 0 ? 0 : _clamp(completions / plays);
  double get favoriteRate => plays == 0 ? 0 : _clamp(favorites / plays);
  double get repeatRate => plays == 0 ? 0 : _clamp(repeats / plays);
}

/// v20: conflict resolution.
class AuroraV20ConflictResolver {
  const AuroraV20ConflictResolver();

  AuroraMode resolve({
    required AuroraMode predicted,
    required AuroraMode learned,
    required double discovery,
    required double familiarity,
  }) {
    if (discovery >= .70 && discovery >= familiarity + .08) {
      return AuroraMode.discovery;
    }
    if (familiarity >= .70 && familiarity >= discovery + .08) {
      return AuroraMode.favorites;
    }
    if (predicted == learned) return predicted;
    if (discovery >= .45 && predicted == AuroraMode.discovery) {
      return AuroraMode.discovery;
    }
    if (familiarity >= .45 && learned == AuroraMode.favorites) {
      return AuroraMode.favorites;
    }
    return AuroraMode.balanced;
  }
}

/// v21: temporary session state.
class AuroraV21SessionState {
  AuroraSessionState _state = AuroraSessionState.start;

  AuroraSessionState get state => _state;

  AuroraSessionState update(AuroraSessionSnapshot s) {
    if (s.plays == 0) {
      _state = AuroraSessionState.start;
    } else if (s.skipRate >= .60 && s.plays >= 3) {
      _state = AuroraSessionState.discovery;
    } else if (s.completionRate >= .80 && s.minutes >= 20) {
      _state = AuroraSessionState.deepListening;
    } else if (s.skipRate >= .35) {
      _state = AuroraSessionState.fatigued;
    } else if (s.completionRate >= .65) {
      _state = AuroraSessionState.engaged;
    } else {
      _state = AuroraSessionState.exploring;
    }
    return _state;
  }

  void reset() => _state = AuroraSessionState.reset;
}

/// v22: session momentum.
class AuroraV22Momentum {
  double _value = 0;

  double get value => _value;

  double update(AuroraSessionSnapshot s) {
    final positive =
        s.completionRate * .50 +
        s.favoriteRate * .30 +
        s.repeatRate * .20;
    _value = (_value * .65) +
        ((_clamp(positive - s.skipRate, min: -1, max: 1)) * .35);
    return _value;
  }

  void reset() => _value = 0;
}

/// v23: candidate skip prediction.
class AuroraV23SkipPrediction {
  const AuroraV23SkipPrediction();

  double probability({
    required double preference,
    required double familiarity,
    required AuroraSessionSnapshot session,
  }) {
    var result = (1 - preference) * .55 +
        session.skipRate * .30 +
        (familiarity < .15 ? .10 : 0);
    return _clamp(result);
  }
}

/// v24: transition scoring.
class AuroraV24Transitions {
  const AuroraV24Transitions();

  double score({
    required String artist,
    required String album,
    required String previousArtist,
    required String previousAlbum,
    required double energy,
    required double previousEnergy,
  }) {
    var score = .50;
    if (_same(artist, previousArtist)) score -= .18;
    if (_same(album, previousAlbum)) score -= .08;
    score += (energy - previousEnergy).abs() <= .20 ? .15 : -.08;
    return _clamp(score);
  }
}

/// v25: diversity scoring.
class AuroraV25Diversity {
  const AuroraV25Diversity();

  double score({
    required String artist,
    required String album,
    required String genre,
    required Iterable<String> artists,
    required Iterable<String> albums,
    required Iterable<String> genres,
  }) {
    var score = 0.0;
    if (artists.any((x) => _same(x, artist))) score -= .22;
    if (albums.any((x) => _same(x, album))) score -= .10;
    if (genres.any((x) => _same(x, genre))) score -= .08;
    return score;
  }
}

/// v26: queue length policy.
class AuroraV26QueueLength {
  const AuroraV26QueueLength({this.min = 5, this.max = 15});

  final int min;
  final int max;

  int resolve({
    required AuroraSessionSnapshot session,
    required AuroraMode mode,
    required double confidence,
  }) {
    var result = 10;
    if (session.skipRate >= .50) result -= 3;
    if (session.completionRate >= .75) result += 3;
    if (mode == AuroraMode.discovery) result += 2;
    if (confidence < .40) result -= 2;
    return result.clamp(min, max);
  }
}

/// v27: next-track fit.
class AuroraV27NextTrack {
  const AuroraV27NextTrack();

  double score({
    required double preference,
    required double completionProbability,
    required double transitionFit,
    required double skipProbability,
  }) =>
      _clamp(
        preference * .42 +
        completionProbability * .28 +
        transitionFit * .20 -
        skipProbability * .10,
      );
}

/// v28: bounded context scoring.
class AuroraV28Context {
  const AuroraV28Context();

  double score({
    required double energy,
    required AuroraSessionSnapshot session,
    required int hour,
  }) {
    var result = .50;
    if (hour >= 22 || hour < 7) result += (1 - energy) * .20;
    if (session.minutes >= 60) result += (1 - energy) * .10;
    return _clamp(result);
  }
}

/// v29: automatic mode inference.
class AuroraV29ModeInference {
  const AuroraV29ModeInference();

  AuroraMode infer({
    required AuroraSessionSnapshot session,
    required AuroraSessionState state,
  }) {
    if (state == AuroraSessionState.discovery ||
        session.skipRate >= .50) {
      return AuroraMode.discovery;
    }
    if (session.completionRate >= .75 && session.minutes >= 20) {
      return AuroraMode.favorites;
    }
    if (session.minutes >= 45) return AuroraMode.chill;
    return AuroraMode.balanced;
  }
}

/// v30: separates persistent and temporary preference layers.
class AuroraV30TasteLayers {
  AuroraV30TasteLayers({
    Map<String, double>? persistent,
    Map<String, double>? temporary,
  })  : _persistent = Map<String, double>.from(persistent ?? const {}),
        _temporary = Map<String, double>.from(temporary ?? const {});

  final Map<String, double> _persistent;
  final Map<String, double> _temporary;

  Map<String, double> get persistent => Map.unmodifiable(_persistent);
  Map<String, double> get temporary => Map.unmodifiable(_temporary);

  double score(String key) =>
      _clamp((_persistent[key] ?? 0) * .70 + (_temporary[key] ?? 0) * .30);

  void learnTemporary(String key, double value) {
    _temporary[key] = _clamp(value, min: -1, max: 1);
  }

  void learnPersistent(String key, double value) {
    _persistent[key] = _clamp(value, min: -1, max: 1);
  }

  void clearTemporary() => _temporary.clear();
}

/// v31: long-term taste decay.
class AuroraV31TasteDecay {
  const AuroraV31TasteDecay({this.halfLifeDays = 90});

  final double halfLifeDays;

  double apply({
    required double value,
    required double ageDays,
  }) {
    if (halfLifeDays <= 0) return value;
    return value *
        math.pow(.5, ageDays / halfLifeDays).toDouble();
  }
}

/// v32: dormant preference recovery.
enum AuroraPreferenceState { active, dormant, unknown }

class AuroraV32PreferenceRecovery {
  const AuroraV32PreferenceRecovery({this.dormantAfterDays = 45});

  final int dormantAfterDays;

  AuroraPreferenceState state({
    required double preference,
    required int inactiveDays,
  }) {
    if (preference.abs() < .15) return AuroraPreferenceState.unknown;
    if (inactiveDays >= dormantAfterDays) {
      return AuroraPreferenceState.dormant;
    }
    return AuroraPreferenceState.active;
  }
}

/// v33: unified recommendation result.
class AuroraV33Recommendation {
  const AuroraV33Recommendation({
    required this.mode,
    required this.state,
    required this.confidence,
    required this.momentum,
    required this.queueLength,
  });

  final AuroraMode mode;
  final AuroraSessionState state;
  final double confidence;
  final double momentum;
  final int queueLength;
}

/// v34: explainable recommendation reasons.
class AuroraV34Explanation {
  const AuroraV34Explanation({
    required this.title,
    required this.scores,
  });

  final String title;
  final Map<String, double> scores;

  String get topReason {
    if (scores.isEmpty) return 'current queue strategy';
    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }
}

/// v35/v36: UI-safe presentation object.
class AuroraV35QueuePresentation {
  const AuroraV35QueuePresentation({
    required this.mode,
    required this.confidence,
    required this.headline,
  });

  final AuroraMode mode;
  final double confidence;
  final String headline;
}

/// v37: explicit user feedback.
class AuroraV37Feedback {
  final List<AuroraFeedbackType> _items = [];

  List<AuroraFeedbackType> get items => List.unmodifiable(_items);

  void add(AuroraFeedbackType feedback) => _items.add(feedback);

  int count(AuroraFeedbackType feedback) =>
      _items.where((item) => item == feedback).length;

  void reset() => _items.clear();
}

/// v38: dependency-free vector value object. A future embedding provider can
/// map its output into this type without changing the queue architecture.
class AuroraV38Embedding {
  const AuroraV38Embedding(this.values);

  final List<double> values;

  double cosine(AuroraV38Embedding other) {
    final length = math.min(values.length, other.values.length);
    if (length == 0) return 0;

    var dot = 0.0;
    var a = 0.0;
    var b = 0.0;

    for (var i = 0; i < length; i++) {
      dot += values[i] * other.values[i];
      a += values[i] * values[i];
      b += other.values[i] * other.values[i];
    }

    if (a == 0 || b == 0) return 0;
    return dot / (math.sqrt(a) * math.sqrt(b));
  }
}

/// v39: deterministic semantic fallback. No package/API required.
class AuroraV39SemanticDiscovery {
  const AuroraV39SemanticDiscovery();

  AuroraSemanticIntent parse(String text) {
    final value = text.toLowerCase();
    var energy = .50;
    var mood = .50;
    var discovery = .50;

    if (_containsAny(value, ['energetic', 'hype', 'upbeat'])) {
      energy += .30;
    }
    if (_containsAny(value, ['calm', 'chill', 'relax', 'dreamy'])) {
      energy -= .20;
      mood += .20;
    }
    if (_containsAny(value, ['new', 'fresh', 'discover', 'unknown'])) {
      discovery += .35;
    }
    if (_containsAny(value, ['favorite', 'familiar', 'known'])) {
      discovery -= .25;
    }

    return AuroraSemanticIntent(
      query: text,
      energy: _clamp(energy),
      mood: _clamp(mood),
      discovery: _clamp(discovery),
    );
  }
}

class AuroraSemanticIntent {
  const AuroraSemanticIntent({
    required this.query,
    required this.energy,
    required this.mood,
    required this.discovery,
  });

  final String query;
  final double energy;
  final double mood;
  final double discovery;
}

/// v40: final facade. It is intentionally independent of persistent storage.
class AuroraV40PersonalDj {
  AuroraV40PersonalDj({
    AuroraV20ConflictResolver? conflict,
    AuroraV21SessionState? state,
    AuroraV22Momentum? momentum,
    AuroraV26QueueLength? queueLength,
    AuroraV29ModeInference? modeInference,
  })  : conflict = conflict ?? const AuroraV20ConflictResolver(),
        state = state ?? AuroraV21SessionState(),
        momentum = momentum ?? AuroraV22Momentum(),
        queueLength = queueLength ?? const AuroraV26QueueLength(),
        modeInference = modeInference ?? const AuroraV29ModeInference();

  final AuroraV20ConflictResolver conflict;
  final AuroraV21SessionState state;
  final AuroraV22Momentum momentum;
  final AuroraV26QueueLength queueLength;
  final AuroraV29ModeInference modeInference;

  AuroraV33Recommendation recommend({
    required AuroraSessionSnapshot session,
    AuroraMode predicted = AuroraMode.balanced,
    AuroraMode learned = AuroraMode.balanced,
    double discovery = 0,
    double familiarity = 0,
    int? requestedLength,
  }) {
    final sessionState = state.update(session);
    final momentumValue = momentum.update(session);

    final resolved = conflict.resolve(
      predicted: predicted,
      learned: learned,
      discovery: discovery,
      familiarity: familiarity,
    );

    final inferred = modeInference.infer(
      session: session,
      state: sessionState,
    );

    final mode = resolved == AuroraMode.balanced &&
            discovery < .45 &&
            familiarity < .45
        ? inferred
        : resolved;

    final double confidence = math.max(
      _clamp(discovery),
      math.max(
        _clamp(familiarity),
        session.plays >= 3 ? .35 : 0.0,
      ).toDouble(),
    ).toDouble();

    final length = requestedLength ??
        queueLength.resolve(
          session: session,
          mode: mode,
          confidence: confidence,
        );

    return AuroraV33Recommendation(
      mode: mode,
      state: sessionState,
      confidence: confidence,
      momentum: momentumValue,
      queueLength: length,
    );
  }

  void resetSession() {
    state.reset();
    momentum.reset();
  }
}

// Keep the existing v1-v19 SmartQueueService available through this file.
// This is a compile-time compatibility anchor and does not alter it.
SmartQueueService auroraExistingSmartQueueService(
  SmartQueueService service,
) =>
    service;

double _clamp(
  double value, {
  double min = 0,
  double max = 1,
}) =>
    value.clamp(min, max);

bool _same(String a, String b) =>
    a.trim().toLowerCase() == b.trim().toLowerCase();

bool _containsAny(String value, List<String> terms) =>
    terms.any(value.contains);
