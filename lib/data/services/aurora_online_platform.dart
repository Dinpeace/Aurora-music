/// Single additive online orchestration layer for Aurora Music.
class AuroraOnlinePlatform {
  AuroraOnlinePlatform({
    required AuroraOnlineCatalogGateway catalog,
    required AuroraOnlineUserGateway user,
    required AuroraOnlinePlaybackGateway playback,
    required AuroraOnlineCacheGateway cache,
    this.maxHistoryBatchSize = 25,
  })  : _catalog = catalog,
        _user = user,
        _playback = playback,
        _cache = cache;

  final AuroraOnlineCatalogGateway _catalog;
  final AuroraOnlineUserGateway _user;
  final AuroraOnlinePlaybackGateway _playback;
  final AuroraOnlineCacheGateway _cache;
  final int maxHistoryBatchSize;

  AuroraOnlineState _state = AuroraOnlineState.initial();
  AuroraOnlineState get state => _state;

  Future<AuroraOnlineState> refresh({required String userId}) async {
    final id = userId.trim();
    if (id.isEmpty) {
      _state = _state.copyWith(
        status: AuroraOnlineStatus.offline,
        message: 'A user ID is required.',
      );
      return _state;
    }

    _state = _state.copyWith(
      status: AuroraOnlineStatus.syncing,
      message: null,
    );

    try {
      final profile = await _user.getProfile(id);
      _state = _state.copyWith(
        status: AuroraOnlineStatus.online,
        userId: id,
        profile: profile,
        lastSync: DateTime.now(),
      );
    } catch (error) {
      _state = _state.copyWith(
        status: AuroraOnlineStatus.error,
        message: error.toString(),
      );
    }
    return _state;
  }

  Future<AuroraOnlineCatalogResult> search(
    String query, {
    bool preferCache = true,
  }) async {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      return const AuroraOnlineCatalogResult(items: []);
    }

    final key = 'search:${normalized.toLowerCase()}';
    if (preferCache) {
      final cached = await _cache.get(key);
      if (cached is AuroraOnlineCatalogResult) return cached;
    }

    final result = await _catalog.search(normalized);
    await _cache.put(key, result);
    return result;
  }

  Future<AuroraOnlinePlaybackResult?> resolvePlayback(String catalogId) {
    final id = catalogId.trim();
    if (id.isEmpty) return Future.value(null);
    return _playback.resolve(id);
  }

  Future<void> saveProfile(AuroraOnlineProfile profile) async {
    await _user.saveProfile(profile);
    _state = _state.copyWith(
      userId: profile.userId,
      profile: profile,
      lastSync: DateTime.now(),
      status: AuroraOnlineStatus.online,
    );
  }

  Future<void> appendHistory(
    String userId,
    Iterable<AuroraListeningEvent> events,
  ) async {
    final pending = events.toList(growable: false);
    if (pending.isEmpty) return;

    final batchSize = maxHistoryBatchSize < 1 ? 1 : maxHistoryBatchSize;
    for (var start = 0; start < pending.length; start += batchSize) {
      final end = (start + batchSize).clamp(0, pending.length);
      await _user.appendHistory(userId, pending.sublist(start, end));
    }
    _state = _state.copyWith(lastSync: DateTime.now());
  }

  Future<void> updateFavorites(
    String userId,
    Iterable<String> songIds,
  ) async {
    final normalized = songIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    await _user.updateFavorites(userId, normalized);
    await _cache.remove('profile:${userId.trim()}');
  }

  Future<void> savePlaylist(
    String userId,
    AuroraOnlinePlaylist playlist,
  ) async {
    await _user.savePlaylist(userId, playlist);
    await _cache.remove('profile:${userId.trim()}');
  }

  Future<void> invalidateCatalogCache() => _cache.removePrefix('search:');

  Future<void> clearUserCache(String userId) =>
      _cache.remove('profile:${userId.trim()}');
}

enum AuroraOnlineStatus { initial, syncing, online, offline, error }

class AuroraOnlineState {
  const AuroraOnlineState({
    required this.status,
    this.userId,
    this.profile,
    this.lastSync,
    this.message,
  });

  factory AuroraOnlineState.initial() =>
      const AuroraOnlineState(status: AuroraOnlineStatus.initial);

  final AuroraOnlineStatus status;
  final String? userId;
  final AuroraOnlineProfile? profile;
  final DateTime? lastSync;
  final String? message;

  AuroraOnlineState copyWith({
    AuroraOnlineStatus? status,
    String? userId,
    AuroraOnlineProfile? profile,
    DateTime? lastSync,
    String? message,
  }) =>
      AuroraOnlineState(
        status: status ?? this.status,
        userId: userId ?? this.userId,
        profile: profile ?? this.profile,
        lastSync: lastSync ?? this.lastSync,
        message: message,
      );
}

abstract interface class AuroraOnlineCatalogGateway {
  Future<AuroraOnlineCatalogResult> search(String query);
}

abstract interface class AuroraOnlineUserGateway {
  Future<AuroraOnlineProfile?> getProfile(String userId);
  Future<void> saveProfile(AuroraOnlineProfile profile);
  Future<void> appendHistory(
    String userId,
    List<AuroraListeningEvent> events,
  );
  Future<void> updateFavorites(String userId, List<String> songIds);
  Future<void> savePlaylist(
    String userId,
    AuroraOnlinePlaylist playlist,
  );
}

abstract interface class AuroraOnlinePlaybackGateway {
  Future<AuroraOnlinePlaybackResult?> resolve(String catalogId);
}

abstract interface class AuroraOnlineCacheGateway {
  Future<Object?> get(String key);
  Future<void> put(String key, Object value);
  Future<void> remove(String key);
  Future<void> removePrefix(String prefix);
}

class AuroraOnlineCatalogResult {
  const AuroraOnlineCatalogResult({required this.items});
  final List<AuroraOnlineCatalogItem> items;

  factory AuroraOnlineCatalogResult.fromItems(
    Iterable<AuroraOnlineCatalogItem> items,
  ) =>
      AuroraOnlineCatalogResult(items: List.unmodifiable(items));
}

class AuroraOnlineCatalogItem {
  const AuroraOnlineCatalogItem({
    required this.id,
    required this.title,
    required this.artist,
    this.artworkUrl,
  });
  final String id;
  final String title;
  final String artist;
  final String? artworkUrl;
}

class AuroraOnlinePlaybackResult {
  const AuroraOnlinePlaybackResult({
    required this.catalogId,
    required this.provider,
    required this.providerId,
    required this.available,
  });
  final String catalogId;
  final String provider;
  final String providerId;
  final bool available;
}

class AuroraOnlineProfile {
  const AuroraOnlineProfile({
    required this.userId,
    this.displayName,
    this.favoriteSongIds = const [],
    this.playlists = const [],
  });
  final String userId;
  final String? displayName;
  final List<String> favoriteSongIds;
  final List<AuroraOnlinePlaylist> playlists;
}

class AuroraOnlinePlaylist {
  const AuroraOnlinePlaylist({
    required this.id,
    required this.name,
    this.songIds = const [],
  });
  final String id;
  final String name;
  final List<String> songIds;
}

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

class AuroraOnlineMemoryCache implements AuroraOnlineCacheGateway {
  final Map<String, Object> _values = {};

  @override
  Future<Object?> get(String key) async => _values[key];

  @override
  Future<void> put(String key, Object value) async => _values[key] = value;

  @override
  Future<void> remove(String key) async => _values.remove(key);

  @override
  Future<void> removePrefix(String prefix) async {
    _values.removeWhere((key, _) => key.startsWith(prefix));
  }
}
