Aurora Music — Cloud Auth & Secure Session Single Bundle

One additive authentication/session foundation for the online Aurora platform.

Included:
- sign-in state management
- session restore
- access/refresh session model
- refresh-window validation
- sign-out lifecycle
- secure-session storage interface
- multi-device session metadata
- authentication failure state
- replaceable cloud auth gateway
- deterministic in-memory store for tests

Security boundary:
The service never writes tokens to logs. The production implementation of
AuroraSecureSessionStore should use OS-backed secure storage/keychain or an
equivalent protected credential store. Do not use ordinary plaintext
preferences for production refresh/access tokens.

Production architecture:
Flutter -> Auth Manager -> HTTPS auth gateway -> Aurora Cloud.

No localhost dependency and no new package dependency are introduced.
Smart Queue v1-v60 and previous cloud/sync layers remain untouched.

Previous clean baseline: 194 tests.
Run after extraction:
flutter analyze
flutter test
