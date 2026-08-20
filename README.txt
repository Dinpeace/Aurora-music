Aurora Music — Smart Queue v19

Multi-Signal Queue Intelligence.

v19 introduces QueueIntelligenceCoordinator as the single decision layer
between the existing intelligence services and future queue strategy.

Inputs:
- PredictiveQueueIntentService
- ContinuousSessionLearningService
- SessionPatternRecognitionService
- SessionIntelligenceService

Outputs:
- ListeningMode
- confidence
- discovery signal
- familiarity signal
- recognized patterns
- current session counts

Design:
- deterministic signal fusion
- discovery can override familiarity when rejection is strong
- temporary session intelligence only
- reset does not erase persistent listening history
- existing services remain independently testable

Run:
flutter analyze
flutter test

Expected baseline:
106 existing tests + 6 v19 tests = 112 tests.
