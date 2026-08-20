import 'package:dio/dio.dart';

class AuroraCloudCatalogService {
  AuroraCloudCatalogService({
    required Dio dio,
  }) : _dio = dio;

  final Dio _dio;

  Future<List<AuroraCatalogItem>> search(
    String query, {
    int limit = 20,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return const [];

    final response = await _dio.get(
      '/v1/catalog/search',
      queryParameters: {
        'q': q,
        'limit': limit.clamp(1, 100),
      },
    );

    return _items(response.data);
  }

  Future<List<AuroraCatalogItem>> trending({
    int limit = 20,
  }) async {
    final response = await _dio.get(
      '/v1/catalog/trending',
      queryParameters: {'limit': limit.clamp(1, 100)},
    );

    return _items(response.data);
  }

  Future<AuroraCatalogItem?> song(String id) async {
    final value = id.trim();
    if (value.isEmpty) return null;

    try {
      final response = await _dio.get(
        '/v1/catalog/song',
        queryParameters: {'id': value},
      );

      if (response.data is! Map) return null;
      return AuroraCatalogItem.fromJson(response.data as Map);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  List<AuroraCatalogItem> _items(dynamic data) {
    if (data is! Map) return const [];
    final items = data['items'];
    if (items is! List) return const [];

    return items
        .whereType<Map>()
        .map(AuroraCatalogItem.fromJson)
        .where((item) => item.id.isNotEmpty)
        .toList(growable: false);
  }
}

class AuroraCatalogItem {
  const AuroraCatalogItem({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.genres,
    required this.durationMs,
    required this.artworkUrl,
    required this.provider,
    required this.providerId,
    required this.popularity,
    this.streamUrl,
    this.lyricsUrl,
  });

  final String id;
  final String title;
  final String artist;
  final String album;
  final List<String> genres;
  final int durationMs;
  final String artworkUrl;
  final String provider;
  final String providerId;
  final double popularity;
  final String? streamUrl;
  final String? lyricsUrl;

  factory AuroraCatalogItem.fromJson(Map value) {
    final genres = value['genres'];

    return AuroraCatalogItem(
      id: '${value['id'] ?? ''}'.trim(),
      title: '${value['title'] ?? ''}'.trim(),
      artist: '${value['artist'] ?? ''}'.trim(),
      album: '${value['album'] ?? ''}'.trim(),
      genres: genres is List
          ? genres.whereType<String>().toList(growable: false)
          : const [],
      durationMs: _int(value['durationMs']),
      artworkUrl: '${value['artworkUrl'] ?? ''}'.trim(),
      provider: '${value['provider'] ?? ''}'.trim(),
      providerId: '${value['providerId'] ?? ''}'.trim(),
      popularity: _double(value['popularity']),
      streamUrl: _nullable(value['streamUrl']),
      lyricsUrl: _nullable(value['lyricsUrl']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'album': album,
        'genres': genres,
        'durationMs': durationMs,
        'artworkUrl': artworkUrl,
        'provider': provider,
        'providerId': providerId,
        'popularity': popularity,
        'streamUrl': streamUrl,
        'lyricsUrl': lyricsUrl,
      };
}

int _int(dynamic value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;

double _double(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

String? _nullable(dynamic value) =>
    value is String && value.trim().isNotEmpty ? value.trim() : null;
