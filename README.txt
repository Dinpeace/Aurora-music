Aurora Music — Cloud Platform v4-v15 Bundle

This is one additive bundle instead of separate v4, v5, v6... drops.

Covered:
v4  persistent catalog storage contract
v5  catalog synchronization
v6  provider availability
v7  ingestion/domain contract
v8  artwork/CDN metadata
v9  search-index contract
v10 catalog caching
v11 playback-source resolution
v12 lyrics metadata
v13 listening history
v14 favorites/playlists
v15 cloud user profile

Design:
- dependency-free Dart domain layer
- storage/network agnostic interfaces
- in-memory implementations for safe local tests
- provider credentials remain outside Flutter
- playbackReference is opaque metadata, not a raw stream extractor
- no YouTube audio extraction or restriction bypass
- no production localhost dependency
- Smart Queue v1-v60 is untouched
- no new pubspec dependency

IMPORTANT:
This bundle is a cloud-domain foundation, not a complete production backend.
The interfaces are intended to be connected to the existing Aurora HTTPS API,
database, object storage/CDN, authentication, and authorized provider services.
The in-memory stores exist only to make the integration testable without
requiring a local server.

Before committing:
flutter analyze
flutter test

Current baseline before this bundle: 168 passing tests.

Regression fix: catalog search test no longer assumes a single result when multiple entries legitimately match.
