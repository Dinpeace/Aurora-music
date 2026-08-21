import 'package:flutter_test/flutter_test.dart';
import 'package:aurora_music/data/services/aurora_cloud_discovery_service.dart';

class FakeGateway implements AuroraDiscoveryGateway {
  AuroraDiscoveryPage searchPage = const AuroraDiscoveryPage(items: []);
  AuroraDiscoveryPage trendingPage = const AuroraDiscoveryPage(items: []);
  List<AuroraDiscoveryItem> suggestionItems = const [];

  int searchCalls = 0;
  int trendingCalls = 0;
  int suggestionCalls = 0;
  AuroraDiscoveryRequest? lastRequest;

  @override
  Future<AuroraDiscoveryPage> search(AuroraDiscoveryRequest request) async {
    searchCalls++;
    lastRequest = request;
    return searchPage;
  }

  @override
  Future<AuroraDiscoveryPage> trending(
    AuroraDiscoveryRequest request,
  ) async {
    trendingCalls++;
    lastRequest = request;
    return trendingPage;
  }

  @override
  Future<List<AuroraDiscoveryItem>> suggestions(
    String query,
    int limit,
  ) async {
    suggestionCalls++;
    return suggestionItems.take(limit).toList(growable: false);
  }
}

AuroraDiscoveryItem item({
  String id = 'song-1',
  String title = 'Aurora',
  double popularity = .8,
}) =>
    AuroraDiscoveryItem(
      id: id,
      title: title,
      artist: 'Artist',
      album: 'Album',
      genres: const ['pop'],
      moods: const ['calm'],
      popularity: popularity,
    );

void main() {
  test('empty search is a no-op', () async {
    final gateway = FakeGateway();

    final page = await AuroraCloudDiscoveryService(
      gateway: gateway,
    ).search('   ');

    expect(page.items, isEmpty);
    expect(gateway.searchCalls, 0);
  });

  test('search forwards filters, cursor and bounded limit', () async {
    final gateway = FakeGateway()
      ..searchPage = AuroraDiscoveryPage(items: [item()]);

    final service = AuroraCloudDiscoveryService(gateway: gateway);

    final page = await service.search(
      'Aurora',
      filter: const AuroraDiscoveryFilter(
        genres: ['pop'],
        moods: ['calm'],
        artist: 'Artist',
      ),
      cursor: const AuroraDiscoveryCursor('next-1'),
      limit: 500,
    );

    expect(page.items.single.id, 'song-1');
    expect(gateway.lastRequest!.limit, 100);
    expect(gateway.lastRequest!.cursor!.value, 'next-1');
    expect(gateway.lastRequest!.filter.artist, 'Artist');
  });

  test('search results are cached by normalized request key', () async {
    final gateway = FakeGateway()
      ..searchPage = AuroraDiscoveryPage(items: [item()]);
    final cache = AuroraMemoryDiscoveryCache();

    final service = AuroraCloudDiscoveryService(
      gateway: gateway,
      cache: cache,
    );

    await service.search('  Aurora  ');
    await service.search('aurora');

    expect(gateway.searchCalls, 1);
  });

  test('cache key is stable when filter list order changes', () {
    final a = AuroraDiscoveryRequest(
      query: 'Aurora',
      filter: const AuroraDiscoveryFilter(
        genres: ['pop', 'rock'],
        moods: ['calm', 'focus'],
      ),
    );

    final b = AuroraDiscoveryRequest(
      query: 'aurora',
      filter: const AuroraDiscoveryFilter(
        genres: ['rock', 'pop'],
        moods: ['focus', 'calm'],
      ),
    );

    expect(a.cacheKey(), b.cacheKey());
  });

  test('trending returns gateway items and respects limit', () async {
    final gateway = FakeGateway()
      ..trendingPage = AuroraDiscoveryPage(
        items: [item(id: 'one'), item(id: 'two')],
      );

    final results = await AuroraCloudDiscoveryService(
      gateway: gateway,
    ).trending(limit: 2);

    expect(results.map((x) => x.id), ['one', 'two']);
    expect(gateway.trendingCalls, 1);
    expect(gateway.lastRequest!.limit, 2);
  });

  test('suggestions ignore blank queries', () async {
    final gateway = FakeGateway();

    final result = await AuroraCloudDiscoveryService(
      gateway: gateway,
    ).suggestions('  ');

    expect(result, isEmpty);
    expect(gateway.suggestionCalls, 0);
  });

  test('suggestions are bounded', () async {
    final gateway = FakeGateway()
      ..suggestionItems = List.generate(
        10,
        (i) => item(id: 'song-$i'),
      );

    final result = await AuroraCloudDiscoveryService(
      gateway: gateway,
    ).suggestions('aur', limit: 3);

    expect(result, hasLength(3));
    expect(gateway.suggestionCalls, 1);
  });

  test('page exposes cursor state', () {
    const page = AuroraDiscoveryPage(
      items: [],
      nextCursor: AuroraDiscoveryCursor('next'),
    );

    expect(page.hasMore, isTrue);
    expect(page.nextCursor!.value, 'next');
  });

  test('negative limits are safely clamped', () async {
    final gateway = FakeGateway();

    await AuroraCloudDiscoveryService(
      gateway: gateway,
    ).search('aurora', limit: -10);

    expect(gateway.lastRequest!.limit, 1);
  });
}
