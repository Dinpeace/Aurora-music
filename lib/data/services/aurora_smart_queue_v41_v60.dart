import 'dart:math' as math;

/// Aurora Smart Queue v41-v60 master additive layer.
///
/// This file intentionally contains only dependency-free orchestration and
/// value objects. It does not replace v1-v40 services.
enum AuroraV41Mode { balanced, discovery, favorites, focus, chill }

class AuroraV41Track {
  const AuroraV41Track({
    required this.id,
    required this.artist,
    this.album = '',
    this.genre = '',
    this.energy = .5,
    this.preference = .5,
    this.discovery = .5,
    this.transition = .5,
  });
  final String id;
  final String artist;
  final String album;
  final String genre;
  final double energy;
  final double preference;
  final double discovery;
  final double transition;
}

class AuroraV41QueueReport {
  const AuroraV41QueueReport({
    required this.valid,
    required this.duplicates,
    required this.currentQueueLeak,
    required this.emptyIds,
  });
  final bool valid;
  final List<String> duplicates;
  final List<String> currentQueueLeak;
  final int emptyIds;
}

/// v41 — real-world output validation.
class AuroraV41QueueValidator {
  const AuroraV41QueueValidator();

  AuroraV41QueueReport validate(
    Iterable<AuroraV41Track> result, {
    Iterable<AuroraV41Track> current = const [],
  }) {
    final seen = <String>{};
    final duplicates = <String>[];
    final currentIds = current.map((x) => x.id).toSet();
    final leak = <String>[];
    var empty = 0;

    for (final track in result) {
      if (track.id.trim().isEmpty) {
        empty++;
        continue;
      }
      if (!seen.add(track.id)) duplicates.add(track.id);
      if (currentIds.contains(track.id) && !leak.contains(track.id)) {
        leak.add(track.id);
      }
    }

    return AuroraV41QueueReport(
      valid: duplicates.isEmpty && leak.isEmpty && empty == 0,
      duplicates: List.unmodifiable(duplicates),
      currentQueueLeak: List.unmodifiable(leak),
      emptyIds: empty,
    );
  }
}

/// v42 — candidate pool health.
class AuroraV42CandidateHealth {
  const AuroraV42CandidateHealth();

  double score(Iterable<AuroraV41Track> candidates) {
    final list = candidates.toList();
    if (list.isEmpty) return 0;
    final unique = list.map((x) => x.id).toSet().length;
    final diversity = list.map((x) => x.artist).toSet().length /
        math.max(1, list.length);
    return _clamp((unique / list.length) * .65 + diversity * .35);
  }
}

/// v43 — duplicate and repetition guard.
class AuroraV43RepetitionGuard {
  const AuroraV43RepetitionGuard();

  bool allowed({
    required AuroraV41Track candidate,
    required Iterable<AuroraV41Track> recent,
    int artistLimit = 2,
  }) {
    final count = recent.where((x) => _same(x.artist, candidate.artist)).length;
    return count < artistLimit;
  }
}

/// v44 — recommendation stability guard.
class AuroraV44StabilityGuard {
  const AuroraV44StabilityGuard({this.maxChange = .25});
  final double maxChange;

  double stabilize(double previous, double next) {
    final delta = next - previous;
    if (delta.abs() <= maxChange) return _clamp(next, min: -1, max: 1);
    return previous + delta.sign * maxChange;
  }
}

/// v45 — queue regeneration cooldown.
class AuroraV45RegenerationPolicy {
  const AuroraV45RegenerationPolicy({this.cooldownMinutes = 3});
  final int cooldownMinutes;

  bool shouldRegenerate({
    required int minutesSinceLastGeneration,
    required bool userRequested,
  }) =>
      userRequested || minutesSinceLastGeneration >= cooldownMinutes;
}

/// v46 — confidence calibration.
class AuroraV46ConfidenceCalibration {
  const AuroraV46ConfidenceCalibration();

  double calibrate({
    required double raw,
    required int evidenceCount,
  }) {
    final evidenceFactor = 1 - math.exp(-evidenceCount / 5);
    return _clamp(raw * .65 + evidenceFactor * .35);
  }
}

/// v47 — exploration budget.
class AuroraV47ExplorationBudget {
  const AuroraV47ExplorationBudget({
    this.minimum = .10,
    this.maximum = .45,
  });

  final double minimum;
  final double maximum;

  double resolve({
    required AuroraV41Mode mode,
    required double confidence,
  }) {
    if (mode == AuroraV41Mode.discovery) {
      return _clamp(.30 + confidence * .15,
          min: minimum, max: maximum);
    }
    return _clamp(.20 - confidence * .08,
        min: minimum, max: maximum);
  }
}

/// v48 — familiarity budget.
class AuroraV48FamiliarityBudget {
  const AuroraV48FamiliarityBudget();

  double resolve({
    required AuroraV41Mode mode,
    required double confidence,
  }) {
    if (mode == AuroraV41Mode.favorites) {
      return _clamp(.55 + confidence * .20);
    }
    if (mode == AuroraV41Mode.discovery) return .25;
    return .45;
  }
}

/// v49 — queue freshness.
class AuroraV49FreshnessScorer {
  const AuroraV49FreshnessScorer();

  double score({
    required double familiarity,
    required double discovery,
    required bool recentlyPlayed,
  }) {
    var result = discovery * .55 + (1 - familiarity) * .45;
    if (recentlyPlayed) result -= .25;
    return _clamp(result);
  }
}

/// v50 — mid-session adaptation checkpoint.
class AuroraV50AdaptationCheckpoint {
  const AuroraV50AdaptationCheckpoint();

  bool shouldAdapt({
    required int eventsSinceCheckpoint,
    required double momentumDelta,
  }) =>
      eventsSinceCheckpoint >= 3 || momentumDelta.abs() >= .25;
}

/// v51 — session snapshot persistence value object.
class AuroraV51SessionSnapshot {
  const AuroraV51SessionSnapshot({
    required this.timestamp,
    required this.mode,
    required this.confidence,
    required this.momentum,
  });

  final DateTime timestamp;
  final AuroraV41Mode mode;
  final double confidence;
  final double momentum;
}

/// v52 — session comparison.
class AuroraV52SessionComparator {
  const AuroraV52SessionComparator();

  double change(AuroraV51SessionSnapshot a, AuroraV51SessionSnapshot b) =>
      _clamp(
        (b.confidence - a.confidence) +
            (b.momentum - a.momentum) * .5,
        min: -1,
        max: 1,
      );
}

/// v53 — long-term/session signal isolation.
class AuroraV53SignalIsolation {
  const AuroraV53SignalIsolation();

  double combine({
    required double longTerm,
    required double session,
    double sessionWeight = .30,
  }) =>
      _clamp(
        longTerm * (1 - sessionWeight) + session * sessionWeight,
        min: -1,
        max: 1,
      );
}

/// v54 — preference recovery probe.
class AuroraV54RecoveryProbe {
  const AuroraV54RecoveryProbe();

  bool shouldProbe({
    required int inactiveDays,
    required double historicalPreference,
  }) =>
      inactiveDays >= 45 && historicalPreference >= .65;
}

/// v55 — controlled discovery resurfacing.
class AuroraV55DiscoveryResurfacing {
  const AuroraV55DiscoveryResurfacing();

  bool allow({
    required int daysSinceLastSeen,
    required double historicalPreference,
    required double currentDiscoveryPressure,
  }) =>
      historicalPreference >= .55 &&
      daysSinceLastSeen >= 30 &&
      currentDiscoveryPressure >= .30;
}

/// v56 — recommendation audit.
class AuroraV56RecommendationAudit {
  const AuroraV56RecommendationAudit();

  List<String> audit({
    required Iterable<AuroraV41Track> queue,
    Iterable<AuroraV41Track> current = const [],
  }) {
    final report = const AuroraV41QueueValidator().validate(
      queue,
      current: current,
    );
    final issues = <String>[];
    if (report.duplicates.isNotEmpty) issues.add('duplicate_tracks');
    if (report.currentQueueLeak.isNotEmpty) {
      issues.add('current_queue_leak');
    }
    if (report.emptyIds > 0) issues.add('empty_track_ids');
    return List.unmodifiable(issues);
  }
}

/// v57 — safe fallback strategy.
class AuroraV57FallbackStrategy {
  const AuroraV57FallbackStrategy();

  List<AuroraV41Track> select(
    Iterable<AuroraV41Track> candidates, {
    int length = 5,
  }) {
    final list = candidates.toList();
    list.sort((a, b) => b.preference.compareTo(a.preference));
    return List.unmodifiable(list.take(math.max(0, length)));
  }
}

/// v58 — deterministic offline evaluation.
class AuroraV58Evaluation {
  const AuroraV58Evaluation({
    required this.precision,
    required this.diversity,
    required this.stability,
  });

  final double precision;
  final double diversity;
  final double stability;

  double get overall =>
      _clamp(precision * .45 + diversity * .30 + stability * .25);
}

class AuroraV58Evaluator {
  const AuroraV58Evaluator();

  AuroraV58Evaluation evaluate({
    required Iterable<AuroraV41Track> recommended,
    required Iterable<AuroraV41Track> preferred,
  }) {
    final rec = recommended.toList();
    final pref = preferred.map((x) => x.id).toSet();
    final hits = rec.where((x) => pref.contains(x.id)).length;
    final precision = rec.isEmpty ? 0 : hits / rec.length;
    final diversity = rec.isEmpty
        ? 0
        : rec.map((x) => x.artist).toSet().length / rec.length;
    return AuroraV58Evaluation(
      precision: _clamp(precision.toDouble()),
      diversity: _clamp(diversity.toDouble()),
      stability: .75,
    );
  }
}

/// v59 — production readiness gate.
class AuroraV59ReadinessGate {
  const AuroraV59ReadinessGate();

  bool ready({
    required bool analyzerClean,
    required bool testsPassing,
    required bool auditClean,
  }) =>
      analyzerClean && testsPassing && auditClean;
}

/// v60 — final Personal DJ orchestration facade.
class AuroraV60PersonalDj {
  AuroraV60PersonalDj({
    AuroraV41QueueValidator? validator,
    AuroraV42CandidateHealth? health,
    AuroraV43RepetitionGuard? repetition,
    AuroraV44StabilityGuard? stability,
    AuroraV45RegenerationPolicy? regeneration,
    AuroraV46ConfidenceCalibration? confidence,
    AuroraV47ExplorationBudget? exploration,
    AuroraV48FamiliarityBudget? familiarity,
    AuroraV49FreshnessScorer? freshness,
    AuroraV50AdaptationCheckpoint? checkpoint,
    AuroraV56RecommendationAudit? audit,
    AuroraV57FallbackStrategy? fallback,
  })  : validator = validator ?? const AuroraV41QueueValidator(),
        health = health ?? const AuroraV42CandidateHealth(),
        repetition = repetition ?? const AuroraV43RepetitionGuard(),
        stability = stability ?? const AuroraV44StabilityGuard(),
        regeneration =
            regeneration ?? const AuroraV45RegenerationPolicy(),
        confidence =
            confidence ?? const AuroraV46ConfidenceCalibration(),
        exploration =
            exploration ?? const AuroraV47ExplorationBudget(),
        familiarity =
            familiarity ?? const AuroraV48FamiliarityBudget(),
        freshness = freshness ?? const AuroraV49FreshnessScorer(),
        checkpoint =
            checkpoint ?? const AuroraV50AdaptationCheckpoint(),
        audit = audit ?? const AuroraV56RecommendationAudit(),
        fallback = fallback ?? const AuroraV57FallbackStrategy();

  final AuroraV41QueueValidator validator;
  final AuroraV42CandidateHealth health;
  final AuroraV43RepetitionGuard repetition;
  final AuroraV44StabilityGuard stability;
  final AuroraV45RegenerationPolicy regeneration;
  final AuroraV46ConfidenceCalibration confidence;
  final AuroraV47ExplorationBudget exploration;
  final AuroraV48FamiliarityBudget familiarity;
  final AuroraV49FreshnessScorer freshness;
  final AuroraV50AdaptationCheckpoint checkpoint;
  final AuroraV56RecommendationAudit audit;
  final AuroraV57FallbackStrategy fallback;

  List<AuroraV41Track> sanitize(
    Iterable<AuroraV41Track> candidates, {
    Iterable<AuroraV41Track> current = const [],
    int length = 10,
  }) {
    if (length <= 0) return const [];
    final currentIds = current.map((x) => x.id).toSet();
    final seen = <String>{};
    final result = <AuroraV41Track>[];

    for (final track in candidates) {
      if (track.id.trim().isEmpty) continue;
      if (currentIds.contains(track.id)) continue;
      if (!seen.add(track.id)) continue;
      if (!repetition.allowed(
        candidate: track,
        recent: result,
      )) {
        continue;
      }
      result.add(track);
      if (result.length >= length) break;
    }

    if (result.length < length) {
      for (final track in fallback.select(candidates, length: length)) {
        if (currentIds.contains(track.id)) continue;
        if (seen.add(track.id)) result.add(track);
        if (result.length >= length) break;
      }
    }

    return List.unmodifiable(result);
  }

  List<String> auditQueue(
    Iterable<AuroraV41Track> queue, {
    Iterable<AuroraV41Track> current = const [],
  }) =>
      audit.audit(queue: queue, current: current);
}

double _clamp(double value, {double min = 0, double max = 1}) =>
    value.clamp(min, max);

bool _same(String a, String b) =>
    a.trim().toLowerCase() == b.trim().toLowerCase();
