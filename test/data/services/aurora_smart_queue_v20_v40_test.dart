import 'package:flutter_test/flutter_test.dart';
import 'package:aurora_music/data/services/aurora_smart_queue_v20_v40.dart';

void main() {
  test('v20 conflict resolver favors strong discovery', () {
    const resolver = AuroraV20ConflictResolver();
    expect(
      resolver.resolve(
        predicted: AuroraMode.favorites,
        learned: AuroraMode.favorites,
        discovery: .90,
        familiarity: .50,
      ),
      AuroraMode.discovery,
    );
  });

  test('v21 starts safely and enters discovery after repeated skips', () {
    final state = AuroraV21SessionState();
    expect(state.state, AuroraSessionState.start);

    expect(
      state.update(
        const AuroraSessionSnapshot(plays: 5, skips: 4),
      ),
      AuroraSessionState.discovery,
    );
  });

  test('v22 momentum responds to completion and skips', () {
    final momentum = AuroraV22Momentum();

    final positive = momentum.update(
      const AuroraSessionSnapshot(
        plays: 10,
        completions: 9,
        favorites: 2,
      ),
    );
    expect(positive, greaterThan(0));

    final negative = momentum.update(
      const AuroraSessionSnapshot(
        plays: 10,
        skips: 9,
      ),
    );
    expect(negative, lessThan(positive));
  });

  test('v23 skip probability is bounded', () {
    const predictor = AuroraV23SkipPrediction();
    final value = predictor.probability(
      preference: 0,
      familiarity: 0,
      session: const AuroraSessionSnapshot(
        plays: 10,
        skips: 8,
      ),
    );
    expect(value, inInclusiveRange(0, 1));
  });

  test('v24 transition penalizes immediate artist repetition', () {
    const transitions = AuroraV24Transitions();
    final value = transitions.score(
      artist: 'A',
      album: 'B',
      previousArtist: 'A',
      previousAlbum: 'C',
      energy: .5,
      previousEnergy: .5,
    );
    expect(value, lessThan(.5));
  });

  test('v25 diversity penalizes repeated artist', () {
    const diversity = AuroraV25Diversity();
    final value = diversity.score(
      artist: 'A',
      album: 'B',
      genre: 'Pop',
      artists: const ['A'],
      albums: const [],
      genres: const [],
    );
    expect(value, lessThan(0));
  });

  test('v26 queue length remains bounded', () {
    const policy = AuroraV26QueueLength();
    final value = policy.resolve(
      session: const AuroraSessionSnapshot(
        plays: 10,
        completions: 9,
      ),
      mode: AuroraMode.discovery,
      confidence: .9,
    );
    expect(value, inInclusiveRange(5, 15));
  });

  test('v27 next-track score is bounded', () {
    const predictor = AuroraV27NextTrack();
    expect(
      predictor.score(
        preference: .8,
        completionProbability: .8,
        transitionFit: .8,
        skipProbability: .1,
      ),
      inInclusiveRange(0, 1),
    );
  });

  test('v28 context is bounded', () {
    const context = AuroraV28Context();
    expect(
      context.score(
        energy: .2,
        session: const AuroraSessionSnapshot(minutes: 60),
        hour: 23,
      ),
      inInclusiveRange(0, 1),
    );
  });

  test('v29 infers discovery from skip-heavy session', () {
    const inference = AuroraV29ModeInference();
    expect(
      inference.infer(
        session: const AuroraSessionSnapshot(
          plays: 5,
          skips: 4,
        ),
        state: AuroraSessionState.discovery,
      ),
      AuroraMode.discovery,
    );
  });

  test('v30 temporary taste does not mutate persistent taste', () {
    final taste = AuroraV30TasteLayers(
      persistent: const {'artist': .8},
    );
    taste.learnTemporary('artist', -.8);

    expect(taste.persistent['artist'], .8);
    expect(taste.temporary['artist'], -.8);
  });

  test('v31 decay preserves sign and reduces magnitude', () {
    const decay = AuroraV31TasteDecay(halfLifeDays: 90);
    expect(
      decay.apply(value: .8, ageDays: 90),
      closeTo(.4, .0001),
    );
  });

  test('v32 recovers preference status correctly', () {
    const recovery = AuroraV32PreferenceRecovery();
    expect(
      recovery.state(preference: .8, inactiveDays: 10),
      AuroraPreferenceState.active,
    );
    expect(
      recovery.state(preference: .8, inactiveDays: 50),
      AuroraPreferenceState.dormant,
    );
  });

  test('v33-v40 facade works without persistence dependencies', () {
    final dj = AuroraV40PersonalDj();

    final result = dj.recommend(
      session: const AuroraSessionSnapshot(
        plays: 5,
        skips: 4,
        minutes: 10,
      ),
      predicted: AuroraMode.discovery,
      discovery: .8,
    );

    expect(result.mode, AuroraMode.discovery);
    expect(result.queueLength, inInclusiveRange(5, 15));
    expect(result.confidence, greaterThanOrEqualTo(.8));
  });

  test('v37 feedback remains explicit and resettable', () {
    final feedback = AuroraV37Feedback();
    feedback.add(AuroraFeedbackType.moreDiscovery);
    feedback.add(AuroraFeedbackType.moreDiscovery);

    expect(
      feedback.count(AuroraFeedbackType.moreDiscovery),
      2,
    );

    feedback.reset();
    expect(feedback.items, isEmpty);
  });

  test('v38 embedding similarity handles equal vectors', () {
    const a = AuroraV38Embedding([1, 0, 0]);
    const b = AuroraV38Embedding([1, 0, 0]);

    expect(a.cosine(b), closeTo(1, .0001));
  });

  test('v39 semantic fallback understands discovery language', () {
    const semantic = AuroraV39SemanticDiscovery();
    final intent = semantic.parse('something fresh and dreamy');

    expect(intent.discovery, greaterThan(.5));
    expect(intent.energy, lessThan(.6));
  });

  test('v40 reset clears only temporary session state', () {
    final dj = AuroraV40PersonalDj();

    dj.recommend(
      session: const AuroraSessionSnapshot(
        plays: 5,
        skips: 4,
      ),
      discovery: .9,
    );

    dj.resetSession();

    expect(dj.state.state, AuroraSessionState.reset);
    expect(dj.momentum.value, 0);
  });
}
