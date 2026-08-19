Aurora Smart Queue v7

Feedback-aware queue learning built on v6.

Signals:
- repeated skips receive progressively stronger negative weighting
- successful plays receive a positive adaptive signal
- fresh tracks retain novelty exploration
- excluded IDs remain respected
- Smart Queue regeneration automatically consumes the improved ranking
- v5 transition logic remains intact

Run:
flutter analyze
flutter test

Do not commit until all tests pass.
