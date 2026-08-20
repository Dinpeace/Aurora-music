Aurora Music — Cloud Catalog v1 Bundle

Purpose:
Turn the online foundation into a centralized Aurora catalog contract.

Adds:
- server-side catalog repository abstraction
- catalog search
- trending catalog endpoint
- single-song lookup
- normalized song metadata
- Flutter catalog client
- regression tests

API:
GET /v1/catalog/search?q=<query>
GET /v1/catalog/trending
GET /v1/catalog/song?id=<id>

The repository is storage-agnostic. Replace the in-memory repository with a
production database implementation later without changing the Flutter API.

Provider fields preserve:
- Aurora catalog ID
- provider
- provider ID
- artwork
- genres
- duration
- popularity
- optional stream URL
- optional lyrics URL

Important:
- This does not host copyrighted music.
- This does not extract YouTube audio.
- This does not require localhost in production.
- It does not replace Smart Queue v1-v60.
- It does not add Flutter dependencies.

After extraction:
flutter analyze
flutter test

Expected baseline:
existing 159 tests + the new catalog tests.
