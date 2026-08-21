import 'package:flutter_test/flutter_test.dart';
import 'package:aurora_music/data/services/aurora_online_platform.dart';

class FakeCatalog implements AuroraOnlineCatalogGateway {
  int calls = 0;
  @override
  Future<AuroraOnlineCatalogResult> search(String query) async {
    calls++;
    return AuroraOnlineCatalogResult.fromItems([
      AuroraOnlineCatalogItem(id: 'song-1', title: query, artist: 'Aurora'),
    ]);
  }
}

class FakeUser implements AuroraOnlineUserGateway {
  AuroraOnlineProfile? profile;
  final List<List<AuroraListeningEvent>> batches = [];
  List<String>? favorites;
  AuroraOnlinePlaylist? playlist;

  @override
  Future<AuroraOnlineProfile?> getProfile(String userId) async => profile;

  @override
  Future<void> saveProfile(AuroraOnlineProfile value) async => profile = value;

  @override
  Future<void> appendHistory(
    String userId,
    List<AuroraListeningEvent> events,
  ) async => batches.add(events);

  @override
  Future<void> updateFavorites(
    String userId,
    List<String> songIds,
  ) async => favorites = songIds;

  @override
  Future<void> savePlaylist(
    String userId,
    AuroraOnlinePlaylist value,
  ) async => playlist = value;
}

class FakePlayback implements AuroraOnlinePlaybackGateway {
  @override
  Future<AuroraOnlinePlaybackResult?> resolve(String catalogId) async =>
      AuroraOnlinePlaybackResult(
        catalogId: catalogId,
        provider: 'aurora',
        providerId: 'provider-1',
        available: true,
      );
}

AuroraOnlinePlatform platform(
  FakeCatalog catalog,
  FakeUser user,
) =>
    AuroraOnlinePlatform(
      catalog: catalog,
      user: user,
      playback: FakePlayback(),
      cache: AuroraOnlineMemoryCache(),
    );

void main() {
  test('search caches repeated queries', () async {
    final catalog = FakeCatalog();
    final user = FakeUser();
    final p = platform(catalog, user);

    await p.search('Aurora');
    await p.search('Aurora');

    expect(catalog.calls, 1);
  });

  test('refresh loads profile and becomes online', () async {
    final user = FakeUser()
      ..profile = const AuroraOnlineProfile(
        userId: 'user-1',
        displayName: 'Aurora',
      );
    final p = platform(FakeCatalog(), user);

    final state = await p.refresh(userId: 'user-1');

    expect(state.status, AuroraOnlineStatus.online);
    expect(state.profile!.displayName, 'Aurora');
  });

  test('empty user ID becomes offline safely', () async {
    final state = await platform(FakeCatalog(), FakeUser()).refresh(
      userId: '   ',
    );
    expect(state.status, AuroraOnlineStatus.offline);
  });

  test('history is uploaded in bounded batches', () async {
    final user = FakeUser();
    final p = AuroraOnlinePlatform(
      catalog: FakeCatalog(),
      user: user,
      playback: FakePlayback(),
      cache: AuroraOnlineMemoryCache(),
      maxHistoryBatchSize: 2,
    );

    final events = List.generate(
      5,
      (i) => AuroraListeningEvent(
        songId: 'song-$i',
        playedAt: DateTime.utc(2026, 1, 1),
        positionMs: i * 1000,
        completed: true,
      ),
    );

    await p.appendHistory('user-1', events);

    expect(user.batches.map((x) => x.length), [2, 2, 1]);
  });

  test('favorites are normalized and deduplicated', () async {
    final user = FakeUser();
    await platform(FakeCatalog(), user).updateFavorites(
      'user-1',
      const [' song-1 ', 'song-1', '', 'song-2'],
    );

    expect(user.favorites, ['song-1', 'song-2']);
  });

  test('playlist sync delegates to user gateway', () async {
    final user = FakeUser();
    const playlist = AuroraOnlinePlaylist(
      id: 'playlist-1',
      name: 'Favorites',
      songIds: ['song-1'],
    );

    await platform(FakeCatalog(), user).savePlaylist('user-1', playlist);

    expect(user.playlist!.id, 'playlist-1');
    expect(user.playlist!.songIds, ['song-1']);
  });

  test('playback resolution delegates to gateway', () async {
    final result = await platform(FakeCatalog(), FakeUser())
        .resolvePlayback('song-1');

    expect(result!.provider, 'aurora');
    expect(result.available, isTrue);
  });

  test('catalog cache invalidation keeps profile cache', () async {
    final cache = AuroraOnlineMemoryCache();
    await cache.put('search:one', 'a');
    await cache.put('profile:user-1', 'b');

    final p = AuroraOnlinePlatform(
      catalog: FakeCatalog(),
      user: FakeUser(),
      playback: FakePlayback(),
      cache: cache,
    );

    await p.invalidateCatalogCache();

    expect(await cache.get('search:one'), isNull);
    expect(await cache.get('profile:user-1'), 'b');
  });

  test('saving profile updates platform state', () async {
    final p = platform(FakeCatalog(), FakeUser());
    const profile = AuroraOnlineProfile(
      userId: 'user-2',
      displayName: 'Cloud User',
    );

    await p.saveProfile(profile);

    expect(p.state.status, AuroraOnlineStatus.online);
    expect(p.state.userId, 'user-2');
    expect(p.state.profile, profile);
  });
}
