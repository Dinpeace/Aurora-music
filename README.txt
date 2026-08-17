Aurora Smart Queue Adaptive Integration v1

Replaces SmartQueueService's static RecommendationEngine ranking with the
existing AdaptiveRecommendationService.

Now Smart Queue considers:
- repeated plays
- skipped tracks
- listening history
- exploration of unfamiliar artists/albums
- existing artist diversity
- current queue exclusions

The public SmartQueueService API now requires `history`, so callers should
pass the current ListeningHistoryService entries.

Files:
lib/data/services/smart_queue_service.dart
test/data/services/smart_queue_service_test.dart

Run:
flutter pub get
flutter analyze
flutter test
