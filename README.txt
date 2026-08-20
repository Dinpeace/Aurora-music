Aurora Music — Next Feature Bundle

Feature selected after repository review:
Playback Session Persistence & Recovery.

Why this feature:
- The repository already has a substantial PlayerController with playback,
  online playback, equalizer, crossfade, sleep timer, shuffle and repeat.
- PlayerState currently represents the active session in memory.
- This bundle adds a small persistence layer without replacing those existing
  components.
- shared_preferences is already present in pubspec.yaml, so no new dependency
  is required.

Files:
lib/data/services/playback_session_persistence_service.dart
test/data/services/playback_session_persistence_service_test.dart

Compatibility:
- Additive only.
- Does not modify PlayerController.
- Does not modify PlayerState.
- Does not modify Smart Queue v1-v60.
- Uses the existing Song model.
- Uses the existing shared_preferences dependency.

Integration can be wired into PlayerController after this isolated layer passes:
flutter analyze
flutter test
