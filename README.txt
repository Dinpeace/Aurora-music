Aurora Music — Cloud Media & Metadata Single Bundle

One additive metadata layer above the existing Cloud API and Discovery layers.

Included:
- unified canonical Aurora track metadata
- stable Aurora track IDs
- title / artist / album / album artist
- duration and metadata version
- genres and moods
- explicit-content flag
- artwork and thumbnail metadata
- lyrics availability/language/sync metadata
- provider/source metadata
- metadata freshness calculation
- cache-friendly metadata keys
- cache interface + in-memory test implementation
- deterministic regression tests

Architecture:
Flutter -> Media Metadata Service -> existing Cloud API adapter -> HTTPS.

This bundle performs no networking itself and introduces no new dependency.
The existing API layer can implement AuroraMediaMetadataGateway.

No localhost dependency.
Smart Queue v1-v60 and previous auth/sync/API/discovery layers remain untouched.

Previous clean baseline: 222 tests.
Run after extraction:
flutter analyze
flutter test
