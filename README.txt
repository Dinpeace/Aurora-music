Aurora Music — Cloud Data & Discovery Single Bundle

One additive discovery layer built above the existing Cloud API Client.

Included:
- advanced catalog search request model
- genre/mood/artist/album filtering
- popularity threshold model
- cursor-based pagination model
- bounded result limits
- stable cache keys
- search-result caching interface
- trending feed interface
- autocomplete/suggestion interface
- typed discovery result models
- deterministic in-memory cache for tests

This bundle is a domain/gateway layer. The existing HTTPS API adapter can map
AuroraDiscoveryGateway to the project's Cloud API Client without adding another
HTTP dependency.

No localhost dependency.
No new package dependency.
Smart Queue v1-v60 and previous cloud/auth/sync layers remain untouched.

Previous clean baseline: 213 tests.
Run after extraction:
flutter analyze
flutter test
