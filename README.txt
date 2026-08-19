Aurora Smart Queue v5

Adds intelligent transition-aware queue selection on top of v4.

Signals:
- adaptive recommendation remains the base ranking
- session intelligence remains active
- mood continuity comes from MoodEnergyService
- consecutive same-artist tracks are penalized
- consecutive same-album tracks are penalized
- large mood-score jumps receive a small penalty
- nearby mood continuity receives a small bonus
- duplicate/current-queue protection remains intact
- append/regenerate preserve the existing queue

Run:
flutter analyze
flutter test

Do not commit until all tests pass.
