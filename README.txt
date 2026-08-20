Aurora Smart Queue v17

Session Memory & Pattern Recognition.

Builds on v16 with session-scoped recognition of recurring short-term patterns:
- repeated skip -> Discovery
- concentrated artist listening -> Favorites
- completion-heavy sessions -> completion_heavy pattern
- alternating behavior -> balanced-oriented pattern
- bounded memory window
- reset clears only temporary pattern memory
- persistent taste/history remain untouched

Run:
flutter analyze
flutter test

Keep the existing 96-test baseline green and add the v17 regression tests.
