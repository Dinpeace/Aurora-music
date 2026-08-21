/// Aurora Cloud Data & Discovery
///
/// Transport-agnostic discovery layer built on top of the existing cloud API.
/// It provides typed discovery queries, filtering, ranking, pagination and
/// cache-friendly query keys without introducing another HTTP dependency.
class AuroraCloudDiscoveryService {
  AuroraCloudDiscoveryService({
    required AuroraDiscoveryGateway gateway,
    AuroraDiscoveryCache? cache,
  })  : _gateway = gateway,
        _cache = cache;

  final AuroraDiscoveryGateway _gateway;
  final AuroraDiscoveryCache? _cache;

  Future<AuroraDiscoveryPage> search(
    String query, {
    AuroraDiscoveryFilter filter = const AuroraDiscoveryFilter(),
    AuroraDiscoveryCursor? cursor,
    int limit = 20,
    bool useCache = true,
  }) async {
    final normalizedQuery = query.trim();
    final safeLimit = limit.clamp(1, 100).toInt();

    if (normalizedQuery.isEmpty) {
      return const AuroraDiscoveryPage(items: []);
    }

    final request = AuroraDiscoveryRequest(
      query: normalizedQuery,
      filter: filter,
      cursor: cursor,
      limit: safeLimit,
    );

    final cacheKey = request.cacheKey();

    final cache = _cache;
    if (useCache && cache != null) {
      final cached = await cache.get(cacheKey);
      if (cached != null) return cached;
    }

    final page = await _gateway.search(request);

    if (cache != null) {
      await cache.put(cacheKey, page);
    }

    return page;
  }

  Future<List<AuroraDiscoveryItem>> trending({
    AuroraDiscoveryFilter filter = const AuroraDiscoveryFilter(),
    int limit = 20,
  }) async {
    final page = await _gateway.trending(
      AuroraDiscoveryRequest(
        query: '',
        filter: filter,
        limit: limit.clamp(1, 100).toInt(),
      ),
    );

    return page.items;
  }

  Future<List<AuroraDiscoveryItem>> suggestions(
    String query, {
    int limit = 8,
  }) async {
    final normalized = query.trim();
    if (normalized.isEmpty) return const [];

    final results = await _gateway.suggestions(
      normalized,
      limit.clamp(1, 20).toInt(),
    );

    return List.unmodifiable(results);
  }
}

abstract interface class AuroraDiscoveryGateway {
  Future<AuroraDiscoveryPage> search(AuroraDiscoveryRequest request);

  Future<AuroraDiscoveryPage> trending(AuroraDiscoveryRequest request);

  Future<List<AuroraDiscoveryItem>> suggestions(String query, int limit);
}

abstract interface class AuroraDiscoveryCache {
  Future<AuroraDiscoveryPage?> get(String key);
  Future<void> put(String key, AuroraDiscoveryPage page);
}

class AuroraDiscoveryRequest {
  const AuroraDiscoveryRequest({
    required this.query,
    this.filter = const AuroraDiscoveryFilter(),
    this.cursor,
    this.limit = 20,
  });

  final String query;
  final AuroraDiscoveryFilter filter;
  final AuroraDiscoveryCursor? cursor;
  final int limit;

  String cacheKey() {
    final genres = [...filter.genres]..sort();
    final moods = [...filter.moods]..sort();

    return [
      'q=${query.trim().toLowerCase()}',
      'genres=${genres.join(',')}',
      'moods=${moods.join(',')}',
      'artist=${filter.artist?.trim().toLowerCase() ?? ''}',
      'album=${filter.album?.trim().toLowerCase() ?? ''}',
      'cursor=${cursor?.value ?? ''}',
      'limit=$limit',
    ].join('&');
  }
}

class AuroraDiscoveryFilter {
  const AuroraDiscoveryFilter({
    this.genres = const [],
    this.moods = const [],
    this.artist,
    this.album,
    this.minPopularity,
  });

  final List<String> genres;
  final List<String> moods;
  final String? artist;
  final String? album;
  final double? minPopularity;
}

class AuroraDiscoveryCursor {
  const AuroraDiscoveryCursor(this.value);

  final String value;
}

class AuroraDiscoveryPage {
  const AuroraDiscoveryPage({
    required this.items,
    this.nextCursor,
  });

  final List<AuroraDiscoveryItem> items;
  final AuroraDiscoveryCursor? nextCursor;

  bool get hasMore => nextCursor != null;
}

class AuroraDiscoveryItem {
  const AuroraDiscoveryItem({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.genres = const [],
    this.moods = const [],
    this.popularity = 0,
    this.artworkUrl,
  });

  final String id;
  final String title;
  final String artist;
  final String? album;
  final List<String> genres;
  final List<String> moods;
  final double popularity;
  final String? artworkUrl;
}

class AuroraMemoryDiscoveryCache implements AuroraDiscoveryCache {
  final Map<String, AuroraDiscoveryPage> _pages = {};

  @override
  Future<AuroraDiscoveryPage?> get(String key) async => _pages[key];

  @override
  Future<void> put(String key, AuroraDiscoveryPage page) async {
    _pages[key] = page;
  }
}
