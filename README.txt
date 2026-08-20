Aurora Smart Queue v13

Predictive Queue Intent.

- Predicts temporary Discovery/Favorites/Balanced intent from live session trajectory.
- Uses smoothed confidence to prevent abrupt prediction flips.
- Never mutates persistent taste or listening history.
- Optional SmartQueueService extension consumes the prediction.

Run:
flutter analyze
flutter test
