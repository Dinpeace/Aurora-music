/// Aurora Cloud Auth & Secure Session
///
/// Transport-agnostic authentication/session state for the online platform.
/// Real credentials and tokens must be supplied by a secure backend/auth
/// adapter. This layer deliberately does not log or expose token values.
class AuroraCloudAuthManager {
  AuroraCloudAuthManager({
    required AuroraAuthGateway gateway,
    required AuroraSecureSessionStore store,
    AuroraSessionClock? clock,
  })  : _gateway = gateway,
        _store = store,
        _clock = clock ?? const AuroraSessionClock();

  final AuroraAuthGateway _gateway;
  final AuroraSecureSessionStore _store;
  final AuroraSessionClock _clock;

  AuroraAuthState _state = const AuroraAuthState.signedOut();

  AuroraAuthState get state => _state;

  Future<AuroraAuthState> restore() async {
    final session = await _store.read();

    if (session == null) {
      _state = const AuroraAuthState.signedOut();
      return _state;
    }

    if (session.isExpired(_clock.now())) {
      await _store.clear();
      _state = const AuroraAuthState.signedOut();
      return _state;
    }

    _state = AuroraAuthState.authenticated(session);
    return _state;
  }

  Future<AuroraAuthState> signIn({
    required String provider,
    required String authorizationCode,
  }) async {
    final code = authorizationCode.trim();

    if (provider.trim().isEmpty || code.isEmpty) {
      throw const AuroraAuthException(
        AuroraAuthError.invalidCredentials,
      );
    }

    _state = const AuroraAuthState.authenticating();

    try {
      final session = await _gateway.signIn(
        provider: provider.trim(),
        authorizationCode: code,
      );

      await _store.write(session);
      _state = AuroraAuthState.authenticated(session);
      return _state;
    } catch (error) {
      _state = AuroraAuthState.failure(error.toString());
      rethrow;
    }
  }

  Future<AuroraAuthState> refreshSession() async {
    final current = await _store.read();

    if (current == null) {
      _state = const AuroraAuthState.signedOut();
      return _state;
    }

    if (!current.canRefresh(_clock.now())) {
      await _store.clear();
      _state = const AuroraAuthState.signedOut();
      return _state;
    }

    try {
      final refreshed = await _gateway.refresh(
        refreshToken: current.refreshToken,
      );

      await _store.write(refreshed);
      _state = AuroraAuthState.authenticated(refreshed);
      return _state;
    } catch (error) {
      _state = AuroraAuthState.failure(error.toString());
      rethrow;
    }
  }

  Future<void> signOut() async {
    final current = await _store.read();

    try {
      if (current != null) {
        await _gateway.signOut(session: current);
      }
    } finally {
      await _store.clear();
      _state = const AuroraAuthState.signedOut();
    }
  }

  bool get isAuthenticated => _state.status == AuroraAuthStatus.authenticated;

  String? get userId => _state.session?.userId;

  String? get sessionId => _state.session?.sessionId;
}

abstract interface class AuroraAuthGateway {
  Future<AuroraAuthSession> signIn({
    required String provider,
    required String authorizationCode,
  });

  Future<AuroraAuthSession> refresh({
    required String refreshToken,
  });

  Future<void> signOut({
    required AuroraAuthSession session,
  });
}

/// Implement this with platform secure storage / OS keychain.
/// Do not substitute ordinary plaintext preferences for production tokens.
abstract interface class AuroraSecureSessionStore {
  Future<AuroraAuthSession?> read();
  Future<void> write(AuroraAuthSession session);
  Future<void> clear();
}

class AuroraMemorySecureSessionStore implements AuroraSecureSessionStore {
  AuroraAuthSession? _session;

  @override
  Future<AuroraAuthSession?> read() async => _session;

  @override
  Future<void> write(AuroraAuthSession session) async {
    _session = session;
  }

  @override
  Future<void> clear() async {
    _session = null;
  }
}

class AuroraSessionClock {
  const AuroraSessionClock();

  DateTime now() => DateTime.now();
}

class AuroraAuthSession {
  const AuroraAuthSession({
    required this.userId,
    required this.sessionId,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.refreshExpiresAt,
    this.deviceId,
    this.provider,
  });

  final String userId;
  final String sessionId;

  /// Sensitive credential. Keep it inside secure storage/auth adapters.
  final String accessToken;

  /// Sensitive credential. Keep it inside secure storage/auth adapters.
  final String refreshToken;

  final DateTime expiresAt;
  final DateTime refreshExpiresAt;
  final String? deviceId;
  final String? provider;

  bool isExpired(DateTime now) => !now.isBefore(expiresAt);

  bool canRefresh(DateTime now) => now.isBefore(refreshExpiresAt);
}

enum AuroraAuthStatus {
  signedOut,
  authenticating,
  authenticated,
  failure,
}

class AuroraAuthState {
  const AuroraAuthState({
    required this.status,
    this.session,
    this.message,
  });

  const AuroraAuthState.signedOut()
      : this(status: AuroraAuthStatus.signedOut);

  const AuroraAuthState.authenticating()
      : this(status: AuroraAuthStatus.authenticating);

  AuroraAuthState.authenticated(AuroraAuthSession value)
      : this(
          status: AuroraAuthStatus.authenticated,
          session: value,
        );

  AuroraAuthState.failure(String value)
      : this(
          status: AuroraAuthStatus.failure,
          message: value,
        );

  final AuroraAuthStatus status;
  final AuroraAuthSession? session;
  final String? message;
}

enum AuroraAuthError {
  invalidCredentials,
}

class AuroraAuthException implements Exception {
  const AuroraAuthException(this.error);

  final AuroraAuthError error;

  @override
  String toString() => 'AuroraAuthException: $error';
}
