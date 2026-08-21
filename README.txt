Aurora Music — Cloud API Client Single Bundle

One additive typed client for the existing online Aurora architecture.

Endpoints covered:
GET  /v1/catalog/search
GET  /v1/catalog/song
GET  /v1/catalog/resolve
GET  /v1/user/profile
POST /v1/user/favorites
POST /v1/user/playlists
POST /v1/user/history

Included:
- transport abstraction
- typed request model
- typed catalog/search models
- provider-resolution model
- profile/favorites model
- playlist model
- listening-history serialization
- unified API exception
- deterministic mock transport tests

The transport adapter is responsible for HTTPS, authentication headers,
timeouts, status-code mapping, and actual networking. This bundle deliberately
does not introduce a localhost server or a new HTTP package dependency.

Authentication/session state remains owned by the existing auth layer.
Cloud sync can use this client through an adapter.

Smart Queue v1-v60 and previous cloud layers remain untouched.

Previous clean baseline: 203 tests.
Run after extraction:
flutter analyze
flutter test
