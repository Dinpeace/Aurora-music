Aurora Smart Queue v15

Real-Time Queue Adaptation.

Builds on v14 with live adaptation of the unplayed queue tail:
- confidence-gated adaptation
- current/protected items remain untouched
- only the unprotected tail is regenerated
- redundant same-mode regenerations are suppressed
- generation counter provides a lightweight live-update signal
- reset starts a fresh adaptation cycle
- persistent taste and listening history are not modified

Run:
flutter analyze
flutter test

Keep the existing 87-test baseline green and add the v15 regression tests.
