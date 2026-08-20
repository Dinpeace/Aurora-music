Aurora Music — Cloud Catalog v2 Provider Resolver Bundle

Purpose:
Add provider normalization and source resolution above Cloud Catalog v1.

Adds:
- stable Aurora catalog ID -> provider source mapping
- provider priority
- availability-aware fallback
- quality-based tie breaking
- normalized provider source model
- Flutter resolver client
- regression tests

Resolution example:
Aurora ID
  -> Aurora provider
  -> YouTube provider
  -> licensed provider
  -> selected available source

Important:
- This bundle resolves metadata/source references only.
- It does not extract YouTube audio.
- It does not bypass provider restrictions.
- Provider credentials remain server-side.
- The actual playback layer must use an authorized source.
- No production localhost dependency.
- Smart Queue v1-v60 remains untouched.

After extraction:
flutter analyze
flutter test

The current repository baseline before this bundle is 162 passing tests.
