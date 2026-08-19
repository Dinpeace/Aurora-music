Aurora Smart Queue v4 — Complete Compile Fix

This replaces smart_queue_service.dart with a complete, type-safe v4
implementation.

Fixes:
- removes invalid MoodProfile.energy access
- removes invalid MoodProfile.valence access
- uses MoodEnergyService.analyze(song, mood).score
- defines _ContextCandidate
- gives scored an explicit List<_ContextCandidate> type
- keeps optional session ranking
- preserves adaptive ranking, duplicate filtering, artist diversity,
  append(), and regenerate()

Replace:
lib/data/services/smart_queue_service.dart

Then run:
flutter analyze
flutter test

Do not commit until both are clean.
