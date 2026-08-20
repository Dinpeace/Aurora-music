/// Aurora Cloud Platform v4-v15
///
/// A single additive, dependency-free cloud-domain foundation.
/// The classes are storage/network agnostic: a production API/database can
/// implement the interfaces without changing the Flutter-facing models.
///
/// Covered layers:
/// v4  persistent-catalog contract
/// v5  catalog synchronization
/// v6  provider availability
/// v7  ingestion contract
/// v8  artwork/CDN metadata
/// v9  search-index contract
/// v10 catalog cache
/// v11 playback-source resolution
/// v12 lyrics metadata
/// v13 listening history
/// v14 favorites/playlists
/// v15 cloud user profile
library;

class AuroraCloudPlatformV4V15 {
  AuroraCloudPlatformV4V15({
    AuroraCloudCatalogStore? catalogStore,
    AuroraCloudUserStore? userStore,
    AuroraCloudCache? cache,
  })  : catalog = catalogStore ?? AuroraMemoryCatalogStore(),
        users = userStore ?? AuroraMemoryUserStore(),
        cache = cache ?? AuroraMemoryCache();

  final AuroraCloudCatalogStore catalog;
  final AuroraCloudUserStore users;
  final AuroraCloudCache cache;

  Future<AuroraCatalogEntry?> resolveTrack(String id) async {
    final normalized = id.trim();
    if (normalized.isEmpty) return null;

    final cached = cache.get('track:$normalized');
    if (cached is AuroraCatalogEntry) return cached;

    final entry = await catalog.get(normalized);
    if (entry != null) {
      await cache.put('track:$normalized', entry);
    }
    return entry;
  }

  Future<AuroraCatalogSyncResult> syncCatalog(
    Iterable<AuroraCatalogEntry> incoming, {
    String source = 'cloud',
  }) async {
    var inserted = 0;
    var updated = 0;

    for (final entry in incoming) {
      final existing = await catalog.get(entry.id);
      await catalog.upsert(entry);

      if (existing == null) {
        inserted++;
      } else if (existing != entry) {
        updated++;
      }
    }

    return AuroraCatalogSyncResult(
      source: source,
      inserted: inserted,
      updated: updated,
      totalProcessed: inserted + updated,
    );
  }

  Future<AuroraPlaybackResolution?> resolvePlayback(
    String id, {
    List<String> providerPriority = const ['aurora', 'licensed', 'youtube'],
  }) async {
    final entry = await resolveTrack(id);
    if (entry == null) return null;

    final sources = [...entry.sources];
    sources.sort((a, b) {
      final aRank = _rank(providerPriority, a.provider);
      final bRank = _rank(providerPriority, b.provider);
      if (aRank != bRank) return aRank.compareTo(bRank);

      final availability =
          (b.available ? 1 : 0).compareTo(a.available ? 1 : 0);
      if (availability != 0) return availability;

      return b.qualityScore.compareTo(a.qualityScore);
    });

    return AuroraPlaybackResolution(
      catalogId: entry.id,
      selected: sources.isEmpty
          ? null
          : sources.firstWhere(
              (source) => source.available,
              orElse: () => sources.first,
            ),
      candidates: List.unmodifiable(sources),
    );
  }

  int _rank(List<String> priority, String provider) {
    final index = priority.indexOf(provider);
    return index < 0 ? priority.length : index;
  }
}

// ---------------------------------------------------------------------------
// v4: Persistent catalog contract
// ---------------------------------------------------------------------------

abstract interface class AuroraCloudCatalogStore {
  Future<AuroraCatalogEntry?> get(String id);
  Future<List<AuroraCatalogEntry>> search(String query);
  Future<List<AuroraCatalogEntry>> trending();
  Future<void> upsert(AuroraCatalogEntry entry);
  Future<void> remove(String id);
}

// ---------------------------------------------------------------------------
// v5-v9: synchronization, provider availability, ingestion, artwork, search
// ---------------------------------------------------------------------------

class AuroraCatalogSyncResult {
  const AuroraCatalogSyncResult({
    required this.source,
    required this.inserted,
    required this.updated,
    required this.totalProcessed,
  });

  final String source;
  final int inserted;
  final int updated;
  final int totalProcessed;
}

class AuroraCatalogEntry {
  const AuroraCatalogEntry({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.durationMs,
    required this.genres,
    required this.sources,
    this.artwork,
    this.lyrics,
    this.searchTokens = const [],
    this.popularity = 0,
  });

  final String id;
  final String title;
  final String artist;
  final String album;
  final int durationMs;
  final List<String> genres;
  final List<AuroraProviderAvailability> sources;
  final AuroraArtworkMetadata? artwork;
  final AuroraLyricsMetadata? lyrics;
  final List<String> searchTokens;
  final double popularity;

  AuroraCatalogEntry copyWith({
    String? title,
    String? artist,
    String? album,
    int? durationMs,
    List<String>? genres,
    List<AuroraProviderAvailability>? sources,
    AuroraArtworkMetadata? artwork,
    AuroraLyricsMetadata? lyrics,
    List<String>? searchTokens,
    double? popularity,
  }) {
    return AuroraCatalogEntry(
      id: id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      durationMs: durationMs ?? this.durationMs,
      genres: genres ?? this.genres,
      sources: sources ?? this.sources,
      artwork: artwork ?? this.artwork,
      lyrics: lyrics ?? this.lyrics,
      searchTokens: searchTokens ?? this.searchTokens,
      popularity: popularity ?? this.popularity,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AuroraCatalogEntry &&
        id == other.id &&
        title == other.title &&
        artist == other.artist &&
        album == other.album &&
        durationMs == other.durationMs &&
        popularity == other.popularity &&
        _listEquals(genres, other.genres) &&
        _listEquals(sources, other.sources);
  }

  @override
  int get hashCode => Object.hash(
        id,
        title,
        artist,
        album,
        durationMs,
        popularity,
        Object.hashAll(genres),
        Object.hashAll(sources),
      );
}

class AuroraProviderAvailability {
  const AuroraProviderAvailability({
    required this.provider,
    required this.providerId,
    required this.available,
    this.qualityScore = 0,
    this.region,
    this.playbackReference,
  });

  final String provider;
  final String providerId;
  final bool available;
  final double qualityScore;
  final String? region;

  /// Opaque reference. The playback implementation decides how to use it.
  final String? playbackReference;

  @override
  bool operator ==(Object other) =>
      other is AuroraProviderAvailability &&
      provider == other.provider &&
      providerId == other.providerId &&
      available == other.available &&
      qualityScore == other.qualityScore &&
      region == other.region &&
      playbackReference == other.playbackReference;

  @override
  int get hashCode => Object.hash(
        provider,
        providerId,
        available,
        qualityScore,
        region,
        playbackReference,
      );
}

class AuroraArtworkMetadata {
  const AuroraArtworkMetadata({
    required this.url,
    this.thumbnailUrl,
    this.width,
    this.height,
    this.etag,
  });

  final String url;
  final String? thumbnailUrl;
  final int? width;
  final int? height;
  final String? etag;
}

// ---------------------------------------------------------------------------
// v12: Lyrics metadata
// ---------------------------------------------------------------------------

class AuroraLyricsMetadata {
  const AuroraLyricsMetadata({
    required this.available,
    this.url,
    this.language,
    this.synced = false,
    this.source,
  });

  final bool available;
  final String? url;
  final String? language;
  final bool synced;
  final String? source;
}

// ---------------------------------------------------------------------------
// v10: Cloud cache contract
// ---------------------------------------------------------------------------

abstract interface class AuroraCloudCache {
  Object? get(String key);
  Future<void> put(String key, Object value, {Duration? ttl});
  Future<void> remove(String key);
  Future<void> clear();
}

class _CacheEntry {
  _CacheEntry(this.value, this.expiresAt);

  final Object value;
  final DateTime? expiresAt;

  bool get expired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);
}

class AuroraMemoryCache implements AuroraCloudCache {
  final Map<String, _CacheEntry> _entries = {};

  @override
  Object? get(String key) {
    final entry = _entries[key];
    if (entry == null) return null;
    if (entry.expired) {
      _entries.remove(key);
      return null;
    }
    return entry.value;
  }

  @override
  Future<void> put(
    String key,
    Object value, {
    Duration? ttl,
  }) async {
    _entries[key] = _CacheEntry(
      value,
      ttl == null ? null : DateTime.now().add(ttl),
    );
  }

  @override
  Future<void> remove(String key) async => _entries.remove(key);

  @override
  Future<void> clear() async => _entries.clear();
}

// ---------------------------------------------------------------------------
// v13-v15: history, favorites, playlists and profile
// ---------------------------------------------------------------------------

class AuroraListeningEvent {
  const AuroraListeningEvent({
    required this.songId,
    required this.playedAt,
    required this.positionMs,
    required this.completed,
  });

  final String songId;
  final DateTime playedAt;
  final int positionMs;
  final bool completed;
}

class AuroraPlaylist {
  const AuroraPlaylist({
    required this.id,
    required this.name,
    this.songIds = const [],
    this.updatedAt,
  });

  final String id;
  final String name;
  final List<String> songIds;
  final DateTime? updatedAt;

  AuroraPlaylist copyWith({
    String? name,
    List<String>? songIds,
    DateTime? updatedAt,
  }) =>
      AuroraPlaylist(
        id: id,
        name: name ?? this.name,
        songIds: songIds ?? this.songIds,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

class AuroraCloudUserProfile {
  const AuroraCloudUserProfile({
    required this.userId,
    this.displayName,
    this.favoriteSongIds = const [],
    this.playlists = const [],
    this.history = const [],
    this.settings = const {},
  });

  final String userId;
  final String? displayName;
  final List<String> favoriteSongIds;
  final List<AuroraPlaylist> playlists;
  final List<AuroraListeningEvent> history;
  final Map<String, String> settings;

  AuroraCloudUserProfile copyWith({
    String? displayName,
    List<String>? favoriteSongIds,
    List<AuroraPlaylist>? playlists,
    List<AuroraListeningEvent>? history,
    Map<String, String>? settings,
  }) =>
      AuroraCloudUserProfile(
        userId: userId,
        displayName: displayName ?? this.displayName,
        favoriteSongIds: favoriteSongIds ?? this.favoriteSongIds,
        playlists: playlists ?? this.playlists,
        history: history ?? this.history,
        settings: settings ?? this.settings,
      );
}

abstract interface class AuroraCloudUserStore {
  Future<AuroraCloudUserProfile?> getProfile(String userId);
  Future<void> saveProfile(AuroraCloudUserProfile profile);
}

class AuroraMemoryUserStore implements AuroraCloudUserStore {
  final Map<String, AuroraCloudUserProfile> _profiles = {};

  @override
  Future<AuroraCloudUserProfile?> getProfile(String userId) async =>
      _profiles[userId.trim()];

  @override
  Future<void> saveProfile(AuroraCloudUserProfile profile) async {
    _profiles[profile.userId] = profile;
  }
}

class AuroraMemoryCatalogStore implements AuroraCloudCatalogStore {
  final Map<String, AuroraCatalogEntry> _entries = {};

  @override
  Future<AuroraCatalogEntry?> get(String id) async => _entries[id.trim()];

  @override
  Future<List<AuroraCatalogEntry>> search(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];

    final values = _entries.values.where((entry) {
      final haystack = [
        entry.title,
        entry.artist,
        entry.album,
        ...entry.genres,
        ...entry.searchTokens,
      ].join(' ').toLowerCase();
      return haystack.contains(q);
    }).toList();

    values.sort((a, b) => b.popularity.compareTo(a.popularity));
    return List.unmodifiable(values);
  }

  @override
  Future<List<AuroraCatalogEntry>> trending() async {
    final values = _entries.values.toList()
      ..sort((a, b) => b.popularity.compareTo(a.popularity));
    return List.unmodifiable(values);
  }

  @override
  Future<void> upsert(AuroraCatalogEntry entry) async {
    _entries[entry.id] = entry;
  }

  @override
  Future<void> remove(String id) async => _entries.remove(id.trim());
}

class AuroraPlaybackResolution {
  const AuroraPlaybackResolution({
    required this.catalogId,
    required this.selected,
    required this.candidates,
  });

  final String catalogId;
  final AuroraProviderAvailability? selected;
  final List<AuroraProviderAvailability> candidates;

  bool get available => selected?.available == true;
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
