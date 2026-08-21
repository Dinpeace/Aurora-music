import 'package:flutter_test/flutter_test.dart';
import 'package:aurora_music/data/services/aurora_cloud_sync_manager.dart';

class FakeTransport implements AuroraSyncTransport {
  int calls = 0;
  int failuresBeforeSuccess;

  FakeTransport({this.failuresBeforeSuccess = 0});

  @override
  Future<void> send(AuroraPendingOperation operation) async {
    calls++;
    if (calls <= failuresBeforeSuccess) {
      throw StateError('temporary failure');
    }
  }
}

AuroraPendingOperation operation(String id) => AuroraPendingOperation(
      id: id,
      type: 'favorite_update',
      payload: {'songId': id},
      createdAt: DateTime.utc(2026, 1, 1),
    );

void main() {
  test('duplicate operation IDs are idempotent', () async {
    final store = AuroraMemoryPendingOperationStore();

    await store.add(operation('same'));
    await store.add(operation('same'));

    expect(await store.pending(), hasLength(1));
  });

  test('successful synchronization removes completed operations', () async {
    final store = AuroraMemoryPendingOperationStore();
    final transport = FakeTransport();

    final manager = AuroraCloudSyncManager(
      transport: transport,
      store: store,
    );

    await manager.enqueue(operation('one'));
    final result = await manager.synchronize();

    expect(result.processed, 1);
    expect(result.succeeded, 1);
    expect(result.failed, 0);
    expect(await store.pending(), isEmpty);
    expect(manager.state.status, AuroraSyncStatus.online);
  });

  test('retry policy allows temporary failures', () async {
    final store = AuroraMemoryPendingOperationStore();
    final transport = FakeTransport(failuresBeforeSuccess: 2);

    final manager = AuroraCloudSyncManager(
      transport: transport,
      store: store,
      retryPolicy: const AuroraRetryPolicy(maxAttempts: 3),
    );

    await manager.enqueue(operation('retry'));
    final result = await manager.synchronize();

    expect(result.succeeded, 1);
    expect(result.failed, 0);
    expect(transport.calls, 3);
  });

  test('failed operation remains pending for later recovery', () async {
    final store = AuroraMemoryPendingOperationStore();
    final transport = FakeTransport(failuresBeforeSuccess: 10);

    final manager = AuroraCloudSyncManager(
      transport: transport,
      store: store,
      retryPolicy: const AuroraRetryPolicy(maxAttempts: 2),
    );

    await manager.enqueue(operation('failed'));
    final result = await manager.synchronize();

    expect(result.failed, 1);
    expect(await store.pending(), hasLength(1));
    expect(manager.state.status, AuroraSyncStatus.degraded);
  });

  test('operations are processed in creation order', () async {
    final store = AuroraMemoryPendingOperationStore();

    await store.add(
      AuroraPendingOperation(
        id: 'later',
        type: 'test',
        payload: const {},
        createdAt: DateTime.utc(2026, 1, 2),
      ),
    );
    await store.add(
      AuroraPendingOperation(
        id: 'first',
        type: 'test',
        payload: const {},
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );

    final values = await store.pending();

    expect(values.map((item) => item.id), ['first', 'later']);
  });

  test('retry backoff grows deterministically', () {
    const policy = AuroraRetryPolicy(
      maxAttempts: 4,
      baseDelay: Duration(milliseconds: 100),
    );

    expect(policy.delayForAttempt(1), const Duration(milliseconds: 100));
    expect(policy.delayForAttempt(2), const Duration(milliseconds: 200));
    expect(policy.delayForAttempt(3), const Duration(milliseconds: 400));
  });

  test('empty synchronization is a no-op', () async {
    final manager = AuroraCloudSyncManager();

    final result = await manager.synchronize();

    expect(result.processed, 0);
    expect(result.succeeded, 0);
    expect(result.failed, 0);
    expect(manager.state.status, AuroraSyncStatus.idle);
  });

  test('enqueue updates pending state', () async {
    final manager = AuroraCloudSyncManager();

    await manager.enqueue(operation('pending'));

    expect(manager.state.status, AuroraSyncStatus.pending);
    expect(manager.state.pendingCount, 1);
  });
}
