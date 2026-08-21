/// Aurora Cloud Media & Metadata
///
/// A single additive metadata domain layer for Aurora Music. It normalizes
/// cloud/provider metadata into a stable Aurora track model, tracks freshness,
/// supports artwork/lyrics/source metadata, and provides cache-friendly keys.
///
/// No networking is performed here. A gateway adapter can connect this layer
/// to the existing Aurora Cloud API Client.
class AuroraCloudMediaMetadataService {
  AuroraCloudMediaMetadataService({
    required AuroraMediaMetadataGateway gateway,
    AuroraMediaMetadataCache? cache,
    AuroraMetadataClock? clock,
  })  : _gateway = gateway,
        _cache = cache,
        _clock = clock ?? const AuroraMetadataClock();

  final AuroraMediaMetadataGateway _gateway;
  final AuroraMediaMetadataCache? _cache;
  final AuroraMetadataClock _clock;

  Future<AuroraUnifiedTrackMetadata?> getTrack(
    String auroraId, {
    bool useCache = true,
  }) async {
    final id = auroraId.trim();
    if (id.isEmpty) return null;

    final cacheKey = 'track:$id';
    final cache = _cache;

    if (useCache && cache != null) {
      final cached = await cache.get(cacheKey);
      if (cached != null && !cached.isStale(_clock.now())) {
        return cached;
      }
    }

    final metadata = await _gateway.fetchTrack(id);
    if (metadata == null) {
      return null;
    }

    if (cache != null) {
      await cache.put(cacheKey, metadata);
    }

    return metadata;
  }

  Future<AuroraArtworkMetadata?> getArtwork(String auroraId) async {
    final metadata = await getTrack(auroraId);
    return metadata?.artwork;
  }

  Future<AuroraLyricsMetadata?> getLyrics(String auroraId) async {
    final metadata = await getTrack(auroraId);
    return metadata?.lyrics;
  }

  Future<AuroraProviderSourceMetadata?> getSource(String auroraId) async {
    final metadata = await getTrack(auroraId);
    return metadata?.source;
  }

  Future<void> invalidate(String auroraId) async {
    final id = auroraId.trim();
    if (id.isEmpty) return;
    await _cache?.remove('track:$id');
  }
}

abstract interface class AuroraMediaMetadataGateway {
  Future<AuroraUnifiedTrackMetadata?> fetchTrack(String auroraId);
}

abstract interface class AuroraMediaMetadataCache {
  Future<AuroraUnifiedTrackMetadata?> get(String key);
  Future<void> put(String key, AuroraUnifiedTrackMetadata metadata);
  Future<void> remove(String key);
}

class AuroraMemoryMediaMetadataCache implements AuroraMediaMetadataCache {
  final Map<String, AuroraUnifiedTrackMetadata> _values = {};

  @override
  Future<AuroraUnifiedTrackMetadata?> get(String key) async => _values[key];

  @override
  Future<void> put(
    String key,
    AuroraUnifiedTrackMetadata metadata,
  ) async {
    _values[key] = metadata;
  }

  @override
  Future<void> remove(String key) async {
    _values.remove(key);
  }
}

class AuroraUnifiedTrackMetadata {
  const AuroraUnifiedTrackMetadata({
    required this.auroraId,
    required this.title,
    required this.artist,
    required this.album,
    required this.durationMs,
    required this.updatedAt,
    this.albumArtist,
    this.artwork,
    this.lyrics,
    this.source,
    this.genres = const [],
    this.moods = const [],
    this.explicit = false,
    this.metadataVersion = 1,
  });

  final String auroraId;
  final String title;
  final String artist;
  final String album;
  final String? albumArtist;
  final int durationMs;
  final List<String> genres;
  final List<String> moods;
  final bool explicit;
  final int metadataVersion;
  final DateTime updatedAt;
  final AuroraArtworkMetadata? artwork;
  final AuroraLyricsMetadata? lyrics;
  final AuroraProviderSourceMetadata? source;

  bool isStale(DateTime now, {Duration maxAge = const Duration(hours: 24)}) {
    return now.difference(updatedAt) > maxAge;
  }

  String get cacheKey => 'track:$auroraId';
}

class AuroraArtworkMetadata {
  const AuroraArtworkMetadata({
    required this.url,
    this.thumbnailUrl,
    this.width,
    this.height,
    this.source,
  });

  final String url;
  final String? thumbnailUrl;
  final int? width;
  final int? height;
  final String? source;
}

class AuroraLyricsMetadata {
  const AuroraLyricsMetadata({
    required this.available,
    this.url,
    this.language,
    this.synced,
    this.provider,
  });

  final bool available;
  final String? url;
  final String? language;
  final bool? synced;
  final String? provider;
}

class AuroraProviderSourceMetadata {
  const AuroraProviderSourceMetadata({
    required this.provider,
    required this.providerId,
    required this.available,
    this.quality,
    this.mimeType,
  });

  final String provider;
  final String providerId;
  final bool available;
  final String? quality;
  final String? mimeType;
}

class AuroraMetadataClock {
  const AuroraMetadataClock();

  DateTime now() => DateTime.now();
}
