Aurora Smart Queue v6

Adaptive queue regeneration built on v5:
- regeneration preserves the existing queue
- already queued tracks are excluded from newly generated additions
- repeated append/regenerate calls remain duplicate-safe
- non-positive regeneration length is a no-op
- transition-aware ordering remains active
- adaptive, session and mood ranking remain the foundation

Run:
flutter analyze
flutter test

Do not commit until all tests pass.
