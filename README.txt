Aurora Smart Queue v14

Predictive Queue Regeneration.

Builds on v13 by allowing the queue tail to react to a confident predicted
session intent without disturbing protected/current items.

- regeneration is confidence-gated
- only the unprotected queue tail is rebuilt
- repeated regeneration of the same applied mode is suppressed
- reset permits a new application
- persistent taste and listening history remain untouched

Run:
flutter analyze
flutter test

Keep the existing 83-test baseline green and add the v14 regression tests.
