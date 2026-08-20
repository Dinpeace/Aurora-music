Aurora Smart Queue v18

Pattern-Aware Queue Strategy.

Builds on v17 by applying recognized session patterns to candidate ordering:
- repeated skip discovery adds a bounded discovery-oriented ranking signal
- artist affinity supports continuation-oriented ranking
- completion-heavy sessions favor continuation-like candidates
- alternating behavior preserves balanced ordering
- upstream SmartQueue ranking remains the base
- no persistent taste/history mutation
- empty pattern memory preserves upstream order

Run:
flutter analyze
flutter test

Target:
101 existing tests + v18 regression tests = 106 tests.
