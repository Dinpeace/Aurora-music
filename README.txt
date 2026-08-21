Aurora Music — Online Platform Single Bundle

One additive bundle for the next online-first development step.

Includes:
- unified online state
- cloud profile refresh
- catalog search with cache
- playback-source resolution gateway
- bounded listening-history synchronization
- favorites synchronization
- playlist synchronization
- catalog cache invalidation
- replaceable catalog/user/playback/cache interfaces
- deterministic in-memory cache for tests

Production:
Flutter -> Aurora HTTPS API -> cloud catalog/user/provider services.

No production localhost dependency is introduced.
No YouTube audio extraction or provider restriction bypass is included.
Smart Queue v1-v60 and previous cloud catalog layers remain untouched.
No new package dependency is required.

Previous clean baseline: 177 tests.
Run after extraction:
flutter analyze
flutter test
