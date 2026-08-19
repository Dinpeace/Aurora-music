Aurora Smart Queue v3

Adds optional session-aware queue adaptation using the existing
SessionIntelligenceService.

Behavior:
- current session plays/skips influence queue ordering
- skipped session tracks are pushed down
- played artists can receive session preference
- existing SmartQueueService callers remain compatible because session is
  optional
- append/regenerate automatically inherit session-aware ordering

Run:
flutter analyze
flutter test

Do not commit until all tests pass.
