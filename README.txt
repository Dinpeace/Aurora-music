Aurora Adaptive Recommendations v1

Adds an adaptive ranking layer on top of the existing TasteProfileService.

Behavior:
- reinforces repeated listening
- strongly lowers repeatedly skipped tracks
- adds a small exploration bonus for unfamiliar artists/albums
- keeps artist diversity in recommendation lists
- supports exclusions and configurable result limits

It does not replace TasteProfileService. It composes with the existing profile
and Listening History data.

Files:
lib/data/services/adaptive_recommendation_service.dart
test/data/services/adaptive_recommendation_service_test.dart

Run:
flutter pub get
flutter analyze
flutter test
