Aurora Music — Cloud Sync & Reliability Single Bundle

One additive bundle for the online-first Aurora architecture.

Included:
- offline pending-operation queue
- deterministic operation IDs / idempotency
- duplicate enqueue protection
- bounded synchronization
- retry policy
- exponential-backoff calculation
- failed-operation retention
- sync state tracking
- replaceable transport and persistence interfaces
- deterministic in-memory implementation for tests

Architecture:
Flutter -> sync manager -> HTTPS transport -> Aurora Cloud.

The transport and persistent store are interfaces so the existing online API
can be connected without coupling this layer to localhost or a particular
database.

Important:
- No production localhost dependency.
- No YouTube audio extraction or restriction bypass.
- Smart Queue v1-v60 remains untouched.
- No new package dependency.
- Backoff calculation is exposed; the manager intentionally does not sleep
  during tests or force delays into the transport layer.

Previous clean baseline: 186 tests.
Run after extraction:
flutter analyze
flutter test
