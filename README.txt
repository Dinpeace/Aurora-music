Aurora Smart Queue v8

Long-term preference learning built on v7.

Signals:
- current profile remains the primary taste signal
- a stable profile is rebuilt from listening history
- long-term preference contributes with a controlled weight
- recent skip/play feedback remains decisive
- fresh tracks retain exploration/novelty
- excluded IDs remain respected
- temporary negative feedback does not permanently erase stable taste

Run:
flutter analyze
flutter test

Do not commit until all tests pass.
