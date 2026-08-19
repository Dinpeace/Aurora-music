Aurora Smart Queue v11

Adaptive Session Intelligence.

Adds a temporary session-mode layer on top of v10:
- waits for enough evidence before switching modes
- repeated skips can move the session toward Discovery
- repeated successful plays can move the session toward Favorites
- hysteresis prevents a single event from causing an abrupt switch
- reset clears only temporary mode state
- persistent TasteProfile/listening history are not modified
- SmartQueueService can consume the inferred mode through buildWithSessionMode()

Run:
flutter analyze
flutter test

Keep the existing 68-test baseline green before committing.
