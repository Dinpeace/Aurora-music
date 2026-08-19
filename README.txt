Aurora Personalized Discovery Polish v1

Adds reusable discovery-policy helpers to PersonalizedDiscoveryService:

- isDiscoveryCandidate() identifies music that is new by track, artist and
  album.
- score() provides a shared service-level ranking entry point for future
  Home/Radio/Daily Mix integrations.

The existing rank() algorithm remains unchanged, including its strong
recent-track penalty.

Apply the patch, then run:
flutter analyze
flutter test

Do not commit until the full suite passes.
