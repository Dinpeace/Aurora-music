import 'package:flutter_test/flutter_test.dart';

import 'package:aurora_music/data/services/aurora_cloud_platform_v4_v15.dart';

AuroraCatalogEntry entry({
  String id = 'song-1',
  String title = 'Aurora',
  double popularity = .8,
}) {
  return AuroraCatalogEntry(
    id: id,
    title: title,
    artist: 'Artist',
    album: 'Album',
    durationMs: 180000,
    genres: const ['pop'],
    sources: const [
      AuroraProviderAvailability(
        provider: 'aurora',
        providerId: 'a-1',
        available: true,
        qualityScore: .9,
      ),
      AuroraProviderAvailability(
        provider: 'youtube',
        providerId: 'y-1',
        available: true,
        qualityScore: .8,
      ),
    ],
    artwork: const AuroraArtworkMetadata(
      url: 'https://example.com/art.jpg',
      thumbnailUrl: 'https://example.com/thumb.jpg',
    ),
    lyrics: const AuroraLyricsMetadata(
      available: true,
      language: 'en',
      synced: true,
    ),
    searchTokens: const ['aurora', 'artist'],
    popularity: popularity,
  );
}

void main() {
  test('catalog sync inserts and updates without network dependencies', () async {
    final platform = AuroraCloudPlatformV4V15();

    final first = await platform.syncCatalog([entry()]);
    expect(first.inserted, 1);
    expect(first.updated, 0);

    final second = await platform.syncCatalog([
      entry(title: 'Aurora Updated', popularity: .95),
    ]);

    expect(second.inserted, 0);
    expect(second.updated, 1);
    expect((await platform.resolveTrack('song-1'))!.title, 'Aurora Updated');
  });

  test('catalog search and trending work through the store contract', () async {
    final platform = AuroraCloudPlatformV4V15();

    await platform.syncCatalog([
      entry(id: 'a', title: 'Ocean', popularity: .2),
      entry(id: 'b', title: 'Aurora Lights', popularity: .9),
    ]);

    final searchResults = await platform.catalog.search('aurora');
    expect(searchResults.map((item) => item.id), containsAll(<String>['a', 'b']));
    expect((await platform.catalog.trending()).first.id, 'b');
  });

  test('track resolution is cached after first catalog lookup', () async {
    final store = AuroraMemoryCatalogStore();
    final cache = AuroraMemoryCache();
    final platform = AuroraCloudPlatformV4V15(
      catalogStore: store,
      cache: cache,
    );

    await store.upsert(entry());
    expect(await platform.resolveTrack('song-1'), isNotNull);

    await store.remove('song-1');
    expect(await platform.resolveTrack('song-1'), isNotNull);
  });

  test('playback resolver respects provider priority and availability', () async {
    final platform = AuroraCloudPlatformV4V15();

    await platform.syncCatalog([
      entry(),
    ]);

    final result = await platform.resolvePlayback(
      'song-1',
      providerPriority: const ['youtube', 'aurora'],
    );

    expect(result, isNotNull);
    expect(result!.available, isTrue);
    expect(result.selected!.provider, 'youtube');
  });

  test('playback resolver falls back when preferred source is unavailable',
      () async {
    final platform = AuroraCloudPlatformV4V15();

    await platform.syncCatalog([
      AuroraCatalogEntry(
        id: 'song-2',
        title: 'Fallback',
        artist: 'Artist',
        album: 'Album',
        durationMs: 100000,
        genres: const [],
        sources: const [
          AuroraProviderAvailability(
            provider: 'aurora',
            providerId: 'a',
            available: false,
            qualityScore: 1,
          ),
          AuroraProviderAvailability(
            provider: 'licensed',
            providerId: 'l',
            available: true,
            qualityScore: .7,
          ),
        ],
      ),
    ]);

    final result = await platform.resolvePlayback(
      'song-2',
      providerPriority: const ['aurora', 'licensed'],
    );

    expect(result!.selected!.provider, 'licensed');
  });

  test('user profile stores favorites, playlists and history', () async {
    final platform = AuroraCloudPlatformV4V15();

    final profile = AuroraCloudUserProfile(
      userId: 'user-1',
      displayName: 'Aurora User',
      favoriteSongIds: const ['song-1'],
      playlists: [
        AuroraPlaylist(
          id: 'playlist-1',
          name: 'Favorites',
          songIds: const ['song-1'],
        ),
      ],
      history: [
        AuroraListeningEvent(
          songId: 'song-1',
          playedAt: DateTime.utc(2026, 1, 1),
          positionMs: 42000,
          completed: false,
        ),
      ],
      settings: const {'theme': 'dark'},
    );

    await platform.users.saveProfile(profile);
    final restored = await platform.users.getProfile('user-1');

    expect(restored, isNotNull);
    expect(restored!.favoriteSongIds, ['song-1']);
    expect(restored.playlists.single.name, 'Favorites');
    expect(restored.history.single.positionMs, 42000);
    expect(restored.settings['theme'], 'dark');
  });

  test('cache supports put, remove and clear', () async {
    final cache = AuroraMemoryCache();

    await cache.put('key', 'value');
    expect(cache.get('key'), 'value');

    await cache.remove('key');
    expect(cache.get('key'), isNull);

    await cache.put('one', 1);
    await cache.put('two', 2);
    await cache.clear();

    expect(cache.get('one'), isNull);
    expect(cache.get('two'), isNull);
  });

  test('invalid IDs safely return null', () async {
    final platform = AuroraCloudPlatformV4V15();

    expect(await platform.resolveTrack('   '), isNull);
    expect(
      await platform.resolvePlayback('   '),
      isNull,
    );
  });

  test('catalog entry preserves artwork and lyrics metadata', () {
    final value = entry();

    expect(value.artwork!.url, contains('example.com'));
    expect(value.artwork!.thumbnailUrl, isNotNull);
    expect(value.lyrics!.available, isTrue);
    expect(value.lyrics!.synced, isTrue);
  });
}
