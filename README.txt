Aurora Music — Cloud Catalog v3 Metadata Matching Bundle

Purpose:
Add deterministic metadata normalization and duplicate/match scoring to the
online Aurora catalog.

Adds:
- normalized metadata
- stable catalog identity keys
- title/artist/album similarity
- duration similarity
- weighted match score
- configurable match threshold
- Flutter-side stable identity helper
- regression tests

Matching is conservative and deterministic. The service does not delete,
merge, or mutate provider records. A production catalog layer can use the
decision to propose/perform deduplication according to its own policy.

Important:
- Server remains authoritative.
- No YouTube audio extraction.
- No provider restriction bypass.
- No localhost requirement.
- Smart Queue v1-v60 remains untouched.
- No new Flutter dependency.

After extraction:
flutter analyze
flutter test

Baseline before this bundle:
165 passing tests.
