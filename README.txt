Aurora Real-time Intelligence v1

Adds a lightweight application-wide listening-intelligence change stream.

Behavior:
- PlayerIntelligenceTracker emits an event after start/progress/complete/skip
  changes are persisted.
- Intelligence Dashboard listens and reloads its current history/profile.
- Made For You listens and recalculates its adaptive recommendations.
- The event contains no player/song state, so consumers cannot accidentally
  use stale recommendation payloads.

Apply the supplied patches to the existing files in the repository.

Verification:
flutter analyze
flutter test

Expected architecture:
Player event
 -> ListeningHistoryService persistence
 -> ListeningIntelligenceEvents
 -> Dashboard/profile refresh
 -> Made For You adaptive refresh
