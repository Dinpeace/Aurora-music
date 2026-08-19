Aurora Smart Queue v12

Session-Aware Queue Evolution.

Builds on v11 with:
- smoothed temporary session confidence
- gradual mode evolution instead of abrupt mode changes
- Discovery from sustained skip pressure
- Favorites from sustained repeated successful plays
- temporary confidence independent of persistent taste
- queue generation using the evolved session mode
- reset clears only session-evolution state

Baseline target:
flutter analyze
flutter test

Keep the existing 73-test suite green and add the v12 regression tests before commit.
