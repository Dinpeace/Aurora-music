Aurora Smart Queue v16

Continuous Session Learning.

Builds on v15 with a continuously updated, ephemeral trajectory:
- learns Discovery pressure incrementally from new skips
- learns Favorites pressure incrementally from successful concentrated plays
- ignores duplicate updates when no new session events arrived
- complements predictive intent instead of replacing it
- reset clears only temporary learning state
- persistent taste and listening history remain untouched

Run:
flutter analyze
flutter test

Keep the existing 91-test baseline green and add the v16 regression tests.
