Aurora Listening Insights v1

Adds a pure, UI-ready summary layer over the existing ListeningHistory and
TasteProfile systems.

Metrics:
- total tracked tracks
- total plays
- total skips
- skip rate
- completion rate
- accumulated listened duration
- top artists
- top albums
- top genres
- favorite artist/track counts

No player changes are required. This is intentionally isolated so the next
UI milestone can consume it without changing playback behavior.

Run:
flutter pub get
flutter analyze
flutter test
