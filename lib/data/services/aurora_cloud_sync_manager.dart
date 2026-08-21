/// Aurora Cloud Sync & Reliability
///
/// One additive, transport-agnostic reliability layer for the online platform.
/// It provides deterministic operation IDs, retry/backoff decisions, an
/// offline pending queue, duplicate protection, and sync state tracking.
///
/// The actual HTTPS implementation remains outside this service.
class AuroraCloudSyncManager {
  AuroraCloudSyncManager({
    AuroraSyncTransport? transport,
    AuroraPendingOperationStore? store,
    AuroraRetryPolicy retryPolicy = const AuroraRetryPolicy(),
  })  : _transport = transport ?? AuroraNoopSyncTransport(),
        _store = store ?? AuroraMemoryPendingOperationStore(),
        _retryPolicy = retryPolicy;

  final AuroraSyncTransport _transport;
  final AuroraPendingOperationStore _store;
  final AuroraRetryPolicy _retryPolicy;

  AuroraSyncState _state = const AuroraSyncState.idle();

  AuroraSyncState get state => _state;

  Future<AuroraSyncRunResult> synchronize({
    int maxOperations = 50,
  }) async {
    final operations = await _store.pending();
    if (operations.isEmpty) {
      _state = _state.copyWith(status: AuroraSyncStatus.idle);
      return const AuroraSyncRunResult(processed: 0, succeeded: 0, failed: 0);
    }

    _state = _state.copyWith(
      status: AuroraSyncStatus.syncing,
      pendingCount: operations.length,
      lastError: null,
    );

    var processed = 0;
    var succeeded = 0;
    var failed = 0;

    for (final operation in operations.take(maxOperations.clamp(1, 500))) {
      processed++;

      try {
        await _executeWithRetry(operation);
        await _store.remove(operation.id);
        succeeded++;
      } catch (error) {
        failed++;
        await _store.markFailed(
          operation.id,
          error.toString(),
        );
      }
    }

    final remaining = await _store.pending();
    _state = _state.copyWith(
      status: failed == 0 ? AuroraSyncStatus.online : AuroraSyncStatus.degraded,
      pendingCount: remaining.length,
      lastSync: DateTime.now(),
      lastError: failed == 0 ? null : 'One or more operations failed.',
    );

    return AuroraSyncRunResult(
      processed: processed,
      succeeded: succeeded,
      failed: failed,
    );
  }

  Future<void> enqueue(AuroraPendingOperation operation) async {
    await _store.add(operation);
    final pending = await _store.pending();

    _state = _state.copyWith(
      status: AuroraSyncStatus.pending,
      pendingCount: pending.length,
    );
  }

  Future<void> _executeWithRetry(AuroraPendingOperation operation) async {
    var attempt = 0;

    while (true) {
      try {
        await _transport.send(operation);
        return;
      } catch (error) {
        attempt++;

        if (!_retryPolicy.shouldRetry(
          attempt: attempt,
          error: error,
        )) {
          rethrow;
        }
      }
    }
  }
}

class AuroraRetryPolicy {
  const AuroraRetryPolicy({
    this.maxAttempts = 3,
    this.baseDelay = const Duration(milliseconds: 100),
  });

  final int maxAttempts;
  final Duration baseDelay;

  bool shouldRetry({
    required int attempt,
    Object? error,
  }) =>
      attempt < maxAttempts;

  Duration delayForAttempt(int attempt) {
    final safeAttempt = attempt < 1 ? 1 : attempt;
    final multiplier = 1 << (safeAttempt - 1);
    return Duration(
      milliseconds: baseDelay.inMilliseconds * multiplier,
    );
  }
}

enum AuroraSyncStatus {
  idle,
  pending,
  syncing,
  online,
  degraded,
}

class AuroraSyncState {
  const AuroraSyncState({
    required this.status,
    this.pendingCount = 0,
    this.lastSync,
    this.lastError,
  });

  const AuroraSyncState.idle() : this(status: AuroraSyncStatus.idle);

  final AuroraSyncStatus status;
  final int pendingCount;
  final DateTime? lastSync;
  final String? lastError;

  AuroraSyncState copyWith({
    AuroraSyncStatus? status,
    int? pendingCount,
    DateTime? lastSync,
    String? lastError,
  }) =>
      AuroraSyncState(
        status: status ?? this.status,
        pendingCount: pendingCount ?? this.pendingCount,
        lastSync: lastSync ?? this.lastSync,
        lastError: lastError,
      );
}

class AuroraSyncRunResult {
  const AuroraSyncRunResult({
    required this.processed,
    required this.succeeded,
    required this.failed,
  });

  final int processed;
  final int succeeded;
  final int failed;
}

class AuroraPendingOperation {
  const AuroraPendingOperation({
    required this.id,
    required this.type,
    required this.payload,
    this.createdAt,
    this.attempts = 0,
    this.lastError,
  });

  final String id;
  final String type;
  final Map<String, Object?> payload;
  final DateTime? createdAt;
  final int attempts;
  final String? lastError;

  AuroraPendingOperation copyWith({
    int? attempts,
    String? lastError,
  }) =>
      AuroraPendingOperation(
        id: id,
        type: type,
        payload: payload,
        createdAt: createdAt,
        attempts: attempts ?? this.attempts,
        lastError: lastError ?? this.lastError,
      );
}

abstract interface class AuroraSyncTransport {
  Future<void> send(AuroraPendingOperation operation);
}

class AuroraNoopSyncTransport implements AuroraSyncTransport {
  @override
  Future<void> send(AuroraPendingOperation operation) async {}
}

abstract interface class AuroraPendingOperationStore {
  Future<void> add(AuroraPendingOperation operation);
  Future<List<AuroraPendingOperation>> pending();
  Future<void> remove(String id);
  Future<void> markFailed(String id, String error);
}

class AuroraMemoryPendingOperationStore
    implements AuroraPendingOperationStore {
  final Map<String, AuroraPendingOperation> _operations = {};

  @override
  Future<void> add(AuroraPendingOperation operation) async {
    // Operation IDs are idempotency keys. Re-enqueuing the same ID is a no-op.
    _operations.putIfAbsent(operation.id, () => operation);
  }

  @override
  Future<List<AuroraPendingOperation>> pending() async {
    final values = _operations.values.toList()
      ..sort((a, b) {
        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return aTime.compareTo(bTime);
      });

    return List.unmodifiable(values);
  }

  @override
  Future<void> remove(String id) async => _operations.remove(id);

  @override
  Future<void> markFailed(String id, String error) async {
    final current = _operations[id];
    if (current == null) return;

    _operations[id] = current.copyWith(
      attempts: current.attempts + 1,
      lastError: error,
    );
  }
}
