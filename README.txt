Aurora Smart Queue v10

Context-aware listening modes built on v9.

Modes:
- Balanced: normal recommendation behavior
- Focus: favors focus/ambient/lo-fi metadata and smoother transitions
- Chill: favors acoustic/chill/ambient/lo-fi metadata
- Discovery: favors unfamiliar artists/albums
- Favorites: favors known favorite artists/albums

Design:
- mode is a per-queue context, not a permanent taste-profile mutation
- v9 time-aware preference decay remains active underneath
- recent feedback remains active
- transition logic adapts to the selected mode
- current queue exclusions remain enforced

Run:
flutter analyze
flutter test

Do not commit until all tests pass.
