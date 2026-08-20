import 'package:flutter_test/flutter_test.dart';
import 'package:aurora_music/data/services/aurora_smart_queue_v41_v60.dart';

AuroraV41Track track(
  String id, {
  String artist = 'Aurora',
  double preference = .8,
  double discovery = .5,
}) =>
    AuroraV41Track(
      id: id,
      artist: artist,
      preference: preference,
      discovery: discovery,
    );

void main() {
  test('v41 validator detects duplicates and queue leakage', () {
    const validator = AuroraV41QueueValidator();
    final report = validator.validate(
      [track('a'), track('a')],
      current: [track('a')],
    );
    expect(report.valid, isFalse);
    expect(report.duplicates, contains('a'));
    expect(report.currentQueueLeak, contains('a'));
  });

  test('v42 candidate health is bounded', () {
    const health = AuroraV42CandidateHealth();
    expect(
      health.score([track('a'), track('b', artist: 'Other')]),
      inInclusiveRange(0, 1),
    );
  });

  test('v43 repetition guard blocks excessive artist repetition', () {
    const guard = AuroraV43RepetitionGuard();
    expect(
      guard.allowed(
        candidate: track('c'),
        recent: [track('a'), track('b')],
      ),
      isFalse,
    );
  });

  test('v44 stability guard limits sudden score changes', () {
    const guard = AuroraV44StabilityGuard(maxChange: .25);
    expect(guard.stabilize(.2, .9), closeTo(.45, .0001));
  });

  test('v45 regeneration policy respects cooldown', () {
    const policy = AuroraV45RegenerationPolicy(cooldownMinutes: 3);
    expect(
      policy.shouldRegenerate(
        minutesSinceLastGeneration: 1,
        userRequested: false,
      ),
      isFalse,
    );
    expect(
      policy.shouldRegenerate(
        minutesSinceLastGeneration: 1,
        userRequested: true,
      ),
      isTrue,
    );
  });

  test('v46 confidence calibration remains bounded', () {
    const calibration = AuroraV46ConfidenceCalibration();
    expect(
      calibration.calibrate(raw: .8, evidenceCount: 10),
      inInclusiveRange(0, 1),
    );
  });

  test('v47 discovery budget stays bounded', () {
    const budget = AuroraV47ExplorationBudget();
    expect(
      budget.resolve(
        mode: AuroraV41Mode.discovery,
        confidence: .9,
      ),
      inInclusiveRange(.10, .45),
    );
  });

  test('v48 favorites receive stronger familiarity budget', () {
    const budget = AuroraV48FamiliarityBudget();
    expect(
      budget.resolve(
        mode: AuroraV41Mode.favorites,
        confidence: .9,
      ),
      greaterThan(.45),
    );
  });

  test('v49 freshness penalizes recently played tracks', () {
    const scorer = AuroraV49FreshnessScorer();
    final fresh = scorer.score(
      familiarity: .4,
      discovery: .7,
      recentlyPlayed: false,
    );
    final recent = scorer.score(
      familiarity: .4,
      discovery: .7,
      recentlyPlayed: true,
    );
    expect(fresh, greaterThan(recent));
  });

  test('v50 checkpoint triggers after enough events', () {
    const checkpoint = AuroraV50AdaptationCheckpoint();
    expect(
      checkpoint.shouldAdapt(
        eventsSinceCheckpoint: 3,
        momentumDelta: 0,
      ),
      isTrue,
    );
  });

  test('v51 snapshot stores immutable session state', () {
    final snapshot = AuroraV51SessionSnapshot(
      timestamp: DateTime(2026, 1, 1),
      mode: AuroraV41Mode.discovery,
      confidence: .8,
      momentum: .4,
    );
    expect(snapshot.mode, AuroraV41Mode.discovery);
    expect(snapshot.confidence, .8);
  });

  test('v52 session comparison is bounded', () {
    const comparator = AuroraV52SessionComparator();
    final a = AuroraV51SessionSnapshot(
      timestamp: DateTime(2026),
      mode: AuroraV41Mode.balanced,
      confidence: .2,
      momentum: -.2,
    );
    final b = AuroraV51SessionSnapshot(
      timestamp: DateTime(2026, 1, 2),
      mode: AuroraV41Mode.discovery,
      confidence: .9,
      momentum: .8,
    );
    expect(comparator.change(a, b), inInclusiveRange(-1, 1));
  });

  test('v53 isolates temporary session influence', () {
    const isolation = AuroraV53SignalIsolation();
    expect(
      isolation.combine(longTerm: .8, session: -.8),
      closeTo(.32, .0001),
    );
  });

  test('v54 recovery probe requires age and preference', () {
    const probe = AuroraV54RecoveryProbe();
    expect(
      probe.shouldProbe(
        inactiveDays: 50,
        historicalPreference: .8,
      ),
      isTrue,
    );
  });

  test('v55 resurfacing is controlled', () {
    const service = AuroraV55DiscoveryResurfacing();
    expect(
      service.allow(
        daysSinceLastSeen: 60,
        historicalPreference: .7,
        currentDiscoveryPressure: .4,
      ),
      isTrue,
    );
  });

  test('v56 audit reports queue issues', () {
    const audit = AuroraV56RecommendationAudit();
    final issues = audit.audit(
      queue: [track('a'), track('a')],
    );
    expect(issues, contains('duplicate_tracks'));
  });

  test('v57 fallback returns highest preference tracks', () {
    const fallback = AuroraV57FallbackStrategy();
    final result = fallback.select(
      [track('low', preference: .2), track('high', preference: .9)],
      length: 1,
    );
    expect(result.first.id, 'high');
  });

  test('v58 evaluation produces bounded overall score', () {
    const evaluation = AuroraV58Evaluator();
    final result = evaluation.evaluate(
      recommended: [track('a'), track('b', artist: 'Other')],
      preferred: [track('a')],
    );
    expect(result.overall, inInclusiveRange(0, 1));
  });

  test('v59 readiness requires all gates', () {
    const gate = AuroraV59ReadinessGate();
    expect(
      gate.ready(
        analyzerClean: true,
        testsPassing: true,
        auditClean: true,
      ),
      isTrue,
    );
    expect(
      gate.ready(
        analyzerClean: true,
        testsPassing: false,
        auditClean: true,
      ),
      isFalse,
    );
  });

  test('v60 facade sanitizes a production queue', () {
    final dj = AuroraV60PersonalDj();
    final result = dj.sanitize(
      [
        track('current'),
        track('a', artist: 'Other'),
        track('a', artist: 'Other'),
        track('b', artist: 'Another'),
      ],
      current: [track('current')],
      length: 2,
    );
    expect(result.map((x) => x.id), ['a', 'b']);
    expect(dj.auditQueue(result), isEmpty);
  });
}
