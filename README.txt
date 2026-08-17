Aurora Player → Intelligence Feedback v1

Adds PlayerIntelligenceTracker and a ready-to-apply PlayerController patch.

Flow:
Player start
  -> ListeningHistoryService
Player progress >= 10s
  -> meaningful-listen signal
Manual next within 30s
  -> skip signal
Playback completion
  -> completion signal
  -> Listening History
  -> Taste Profile / Adaptive Recommendations
  -> Smart Queue / Radio / Made For You

Files:
lib/data/services/player_intelligence_tracker.dart
test/data/services/player_intelligence_tracker_test.dart
patches/player_controller_intelligence.patch

Important:
Apply the patch after adding the tracker. The patch is intentionally small and
targets the existing PlayerController event points; do not replace the entire
controller file.
