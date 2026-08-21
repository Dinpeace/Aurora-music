import 'package:flutter_test/flutter_test.dart';
import 'package:aurora_music/data/services/aurora_cloud_auth_manager.dart';

class FakeGateway implements AuroraAuthGateway {
  int signInCalls = 0;
  int refreshCalls = 0;
  int signOutCalls = 0;

  AuroraAuthSession session = AuroraAuthSession(
    userId: 'user-1',
    sessionId: 'session-1',
    accessToken: 'access',
    refreshToken: 'refresh',
    expiresAt: DateTime.utc(2030, 1, 1),
    refreshExpiresAt: DateTime.utc(2031, 1, 1),
    deviceId: 'device-1',
    provider: 'test',
  );

  @override
  Future<AuroraAuthSession> signIn({
    required String provider,
    required String authorizationCode,
  }) async {
    signInCalls++;
    return session;
  }

  @override
  Future<AuroraAuthSession> refresh({
    required String refreshToken,
  }) async {
    refreshCalls++;
    return session;
  }

  @override
  Future<void> signOut({
    required AuroraAuthSession session,
  }) async {
    signOutCalls++;
  }
}

class FixedClock extends AuroraSessionClock {
  const FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}

AuroraCloudAuthManager manager({
  required FakeGateway gateway,
  required AuroraSecureSessionStore store,
  AuroraSessionClock? clock,
}) =>
    AuroraCloudAuthManager(
      gateway: gateway,
      store: store,
      clock: clock ?? FixedClock(DateTime.utc(2026, 1, 1)),
    );

void main() {
  test('restore returns signed out when no session exists', () async {
    final gateway = FakeGateway();
    final store = AuroraMemorySecureSessionStore();

    final state = await manager(
      gateway: gateway,
      store: store,
    ).restore();

    expect(state.status, AuroraAuthStatus.signedOut);
  });

  test('sign in stores session and becomes authenticated', () async {
    final gateway = FakeGateway();
    final store = AuroraMemorySecureSessionStore();
    final auth = manager(gateway: gateway, store: store);

    final state = await auth.signIn(
      provider: 'test',
      authorizationCode: 'code',
    );

    expect(state.status, AuroraAuthStatus.authenticated);
    expect(auth.isAuthenticated, isTrue);
    expect(auth.userId, 'user-1');
    expect(gateway.signInCalls, 1);
    expect(await store.read(), isNotNull);
  });

  test('blank credentials are rejected before gateway access', () async {
    final gateway = FakeGateway();
    final auth = manager(
      gateway: gateway,
      store: AuroraMemorySecureSessionStore(),
    );

    expect(
      () => auth.signIn(
        provider: ' ',
        authorizationCode: 'code',
      ),
      throwsA(isA<AuroraAuthException>()),
    );
    expect(gateway.signInCalls, 0);
  });

  test('expired stored session is cleared during restore', () async {
    final gateway = FakeGateway();
    final store = AuroraMemorySecureSessionStore();

    await store.write(
      AuroraAuthSession(
        userId: 'user-1',
        sessionId: 'expired',
        accessToken: 'access',
        refreshToken: 'refresh',
        expiresAt: DateTime.utc(2025, 1, 1),
        refreshExpiresAt: DateTime.utc(2025, 12, 1),
      ),
    );

    final state = await manager(
      gateway: gateway,
      store: store,
    ).restore();

    expect(state.status, AuroraAuthStatus.signedOut);
    expect(await store.read(), isNull);
  });

  test('valid stored session is restored', () async {
    final gateway = FakeGateway();
    final store = AuroraMemorySecureSessionStore();

    await store.write(gateway.session);

    final state = await manager(
      gateway: gateway,
      store: store,
    ).restore();

    expect(state.status, AuroraAuthStatus.authenticated);
    expect(state.session!.sessionId, 'session-1');
  });

  test('refresh replaces the stored session', () async {
    final gateway = FakeGateway();
    final store = AuroraMemorySecureSessionStore();

    await store.write(gateway.session);

    final auth = manager(gateway: gateway, store: store);
    final state = await auth.refreshSession();

    expect(state.status, AuroraAuthStatus.authenticated);
    expect(gateway.refreshCalls, 1);
    expect((await store.read())!.refreshToken, 'refresh');
  });

  test('expired refresh window signs out without gateway call', () async {
    final gateway = FakeGateway();
    final store = AuroraMemorySecureSessionStore();

    await store.write(
      AuroraAuthSession(
        userId: 'user-1',
        sessionId: 'session-1',
        accessToken: 'access',
        refreshToken: 'refresh',
        expiresAt: DateTime.utc(2025, 1, 1),
        refreshExpiresAt: DateTime.utc(2025, 12, 1),
      ),
    );

    final auth = manager(
      gateway: gateway,
      store: store,
    );

    final state = await auth.refreshSession();

    expect(state.status, AuroraAuthStatus.signedOut);
    expect(gateway.refreshCalls, 0);
    expect(await store.read(), isNull);
  });

  test('sign out clears local session even if gateway succeeds', () async {
    final gateway = FakeGateway();
    final store = AuroraMemorySecureSessionStore();
    await store.write(gateway.session);

    final auth = manager(gateway: gateway, store: store);
    await auth.signOut();

    expect(auth.state.status, AuroraAuthStatus.signedOut);
    expect(gateway.signOutCalls, 1);
    expect(await store.read(), isNull);
  });

  test('session expiry and refresh windows are deterministic', () {
    final session = AuroraAuthSession(
      userId: 'u',
      sessionId: 's',
      accessToken: 'a',
      refreshToken: 'r',
      expiresAt: DateTime.utc(2026, 1, 2),
      refreshExpiresAt: DateTime.utc(2026, 1, 3),
    );

    expect(
      session.isExpired(DateTime.utc(2026, 1, 1)),
      isFalse,
    );
    expect(
      session.isExpired(DateTime.utc(2026, 1, 2)),
      isTrue,
    );
    expect(
      session.canRefresh(DateTime.utc(2026, 1, 2, 23)),
      isTrue,
    );
    expect(
      session.canRefresh(DateTime.utc(2026, 1, 3)),
      isFalse,
    );
  });
}
