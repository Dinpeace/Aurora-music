/// Aurora Cloud API Client
///
/// A transport-agnostic typed API client for the online Aurora platform.
/// Production code can connect this interface to an HTTPS implementation.
/// Authentication/session credentials remain outside this client.
class AuroraCloudApiClient {
  AuroraCloudApiClient({
    required AuroraHttpTransport transport,
  }) : _transport = transport;

  final AuroraHttpTransport _transport;

  Future<AuroraApiCatalogResponse> searchCatalog(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      return const AuroraApiCatalogResponse(items: []);
    }

    final response = await _transport.request(
      AuroraHttpRequest.get(
        '/v1/catalog/search',
        query: {'q': q},
      ),
    );

    return AuroraApiCatalogResponse.fromJson(response);
  }

  Future<AuroraApiCatalogItem?> getCatalogItem(String id) async {
    final normalized = id.trim();
    if (normalized.isEmpty) return null;

    final response = await _transport.request(
      AuroraHttpRequest.get(
        '/v1/catalog/song',
        query: {'id': normalized},
      ),
    );

    if (response['item'] is! Map) return null;
    return AuroraApiCatalogItem.fromJson(
      Map<String, dynamic>.from(response['item'] as Map),
    );
  }

  Future<AuroraApiResolveResponse?> resolvePlayback(String id) async {
    final normalized = id.trim();
    if (normalized.isEmpty) return null;

    final response = await _transport.request(
      AuroraHttpRequest.get(
        '/v1/catalog/resolve',
        query: {'id': normalized},
      ),
    );

    return AuroraApiResolveResponse.fromJson(response);
  }

  Future<AuroraApiProfile?> getProfile(String userId) async {
    final id = userId.trim();
    if (id.isEmpty) return null;

    final response = await _transport.request(
      AuroraHttpRequest.get(
        '/v1/user/profile',
        query: {'userId': id},
      ),
    );

    if (response['profile'] is! Map) return null;
    return AuroraApiProfile.fromJson(
      Map<String, dynamic>.from(response['profile'] as Map),
    );
  }

  Future<void> updateFavorites({
    required String userId,
    required List<String> songIds,
  }) async {
    await _transport.request(
      AuroraHttpRequest.post(
        '/v1/user/favorites',
        body: {
          'userId': userId.trim(),
          'songIds': songIds
              .map((id) => id.trim())
              .where((id) => id.isNotEmpty)
              .toList(growable: false),
        },
      ),
    );
  }

  Future<AuroraApiPlaylist> savePlaylist({
    required String userId,
    required AuroraApiPlaylist playlist,
  }) async {
    final response = await _transport.request(
      AuroraHttpRequest.post(
        '/v1/user/playlists',
        body: {
          'userId': userId.trim(),
          'playlist': playlist.toJson(),
        },
      ),
    );

    if (response['playlist'] is! Map) {
      throw const AuroraApiException(AuroraApiError.invalidResponse);
    }

    return AuroraApiPlaylist.fromJson(
      Map<String, dynamic>.from(response['playlist'] as Map),
    );
  }

  Future<void> appendHistory({
    required String userId,
    required List<AuroraApiHistoryEvent> events,
  }) async {
    await _transport.request(
      AuroraHttpRequest.post(
        '/v1/user/history',
        body: {
          'userId': userId.trim(),
          'events': events.map((event) => event.toJson()).toList(growable: false),
        },
      ),
    );
  }
}

abstract interface class AuroraHttpTransport {
  Future<Map<String, dynamic>> request(AuroraHttpRequest request);
}

class AuroraHttpRequest {
  const AuroraHttpRequest({
    required this.method,
    required this.path,
    this.query = const {},
    this.body,
  });

  factory AuroraHttpRequest.get(
    String path, {
    Map<String, String> query = const {},
  }) =>
      AuroraHttpRequest(
        method: 'GET',
        path: path,
        query: query,
      );

  factory AuroraHttpRequest.post(
    String path, {
    Map<String, dynamic>? body,
  }) =>
      AuroraHttpRequest(
        method: 'POST',
        path: path,
        body: body,
      );

  final String method;
  final String path;
  final Map<String, String> query;
  final Map<String, dynamic>? body;
}

class AuroraApiCatalogResponse {
  const AuroraApiCatalogResponse({required this.items});

  final List<AuroraApiCatalogItem> items;

  factory AuroraApiCatalogResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    final items = raw is List
        ? raw
            .whereType<Map>()
            .map(
              (item) => AuroraApiCatalogItem.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList(growable: false)
        : const <AuroraApiCatalogItem>[];

    return AuroraApiCatalogResponse(items: List.unmodifiable(items));
  }
}

class AuroraApiCatalogItem {
  const AuroraApiCatalogItem({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    this.durationMs = 0,
    this.artworkUrl,
  });

  final String id;
  final String title;
  final String artist;
  final String album;
  final int durationMs;
  final String? artworkUrl;

  factory AuroraApiCatalogItem.fromJson(Map<String, dynamic> json) =>
      AuroraApiCatalogItem(
        id: '${json['id'] ?? ''}'.trim(),
        title: '${json['title'] ?? ''}'.trim(),
        artist: '${json['artist'] ?? ''}'.trim(),
        album: '${json['album'] ?? ''}'.trim(),
        durationMs: _intValue(json['durationMs']),
        artworkUrl: _nullableString(json['artworkUrl']),
      );
}

class AuroraApiResolveResponse {
  const AuroraApiResolveResponse({
    required this.auroraId,
    required this.selectedProvider,
    required this.selectedProviderId,
    required this.available,
  });

  final String auroraId;
  final String selectedProvider;
  final String selectedProviderId;
  final bool available;

  factory AuroraApiResolveResponse.fromJson(Map<String, dynamic> json) =>
      AuroraApiResolveResponse(
        auroraId: '${json['auroraId'] ?? ''}'.trim(),
        selectedProvider: '${json['selectedProvider'] ?? ''}'.trim(),
        selectedProviderId: '${json['selectedProviderId'] ?? ''}'.trim(),
        available: json['available'] == true,
      );
}

class AuroraApiProfile {
  const AuroraApiProfile({
    required this.userId,
    this.displayName,
    this.favoriteSongIds = const [],
  });

  final String userId;
  final String? displayName;
  final List<String> favoriteSongIds;

  factory AuroraApiProfile.fromJson(Map<String, dynamic> json) =>
      AuroraApiProfile(
        userId: '${json['userId'] ?? ''}'.trim(),
        displayName: _nullableString(json['displayName']),
        favoriteSongIds: _stringList(json['favoriteSongIds']),
      );
}

class AuroraApiPlaylist {
  const AuroraApiPlaylist({
    required this.id,
    required this.name,
    this.songIds = const [],
  });

  final String id;
  final String name;
  final List<String> songIds;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'songIds': songIds,
      };

  factory AuroraApiPlaylist.fromJson(Map<String, dynamic> json) =>
      AuroraApiPlaylist(
        id: '${json['id'] ?? ''}'.trim(),
        name: '${json['name'] ?? ''}'.trim(),
        songIds: _stringList(json['songIds']),
      );
}

class AuroraApiHistoryEvent {
  const AuroraApiHistoryEvent({
    required this.songId,
    required this.playedAt,
    required this.positionMs,
    required this.completed,
  });

  final String songId;
  final DateTime playedAt;
  final int positionMs;
  final bool completed;

  Map<String, dynamic> toJson() => {
        'songId': songId,
        'playedAt': playedAt.toUtc().toIso8601String(),
        'positionMs': positionMs,
        'completed': completed,
      };
}

enum AuroraApiError {
  invalidResponse,
  unauthorized,
  network,
  server,
  unknown,
}

class AuroraApiException implements Exception {
  const AuroraApiException(this.error, {this.message});

  final AuroraApiError error;
  final String? message;

  @override
  String toString() => message == null
      ? 'AuroraApiException: $error'
      : 'AuroraApiException: $error: $message';
}

int _intValue(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}

String? _nullableString(Object? value) {
  if (value is! String) return null;
  final result = value.trim();
  return result.isEmpty ? null : result;
}

List<String> _stringList(Object? value) {
  if (value is! List) return const [];
  return List.unmodifiable(
    value.whereType<String>().map((item) => item.trim()).where((item) => item.isNotEmpty),
  );
}
