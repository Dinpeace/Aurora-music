import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import '../../models/online/online_song.dart';
import 'models/album_response.dart';
import 'models/artist_response.dart';
import 'models/search_response.dart';
import 'models/stream_response.dart';
import 'music_provider.dart';

class ProviderClient implements MusicProvider {
  ProviderClient();

  final Dio _dio = ApiClient.dio;

  @override
  Future<SearchResponse> search(String query) async {
    final response = await _get(
      Endpoints.search,
      queryParameters: {'q': query},
    );

    return SearchResponse(
      songs: _songList(response.data),
    );
  }

  @override
  Future<List<OnlineSong>> getTrending() async {
    final response = await _get(Endpoints.trending);
    return _songList(response.data);
  }

  @override
  Future<List<AlbumResponse>> getAlbums() async {
    final response = await _get(Endpoints.albums);
    return _items(response.data)
        .whereType<Map>()
        .map((item) => AlbumResponse.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList();
  }

  @override
  Future<List<ArtistResponse>> getArtists() async {
    final response = await _get(Endpoints.artists);
    return _items(response.data)
        .whereType<Map>()
        .map((item) => ArtistResponse.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList();
  }

  @override
  Future<StreamResponse> getStream(String songId) async {
    if (songId.trim().isEmpty) {
      throw ArgumentError.value(
        songId,
        'songId',
        'Song ID cannot be empty.',
      );
    }

    final response = await _get(
      Endpoints.song,
      queryParameters: {'id': songId},
    );

    final data = _map(response.data);
    final streamUrl = _text(
      data['streamUrl'] ?? data['stream_url'] ?? data['url'],
    );

    if (streamUrl.isEmpty) {
      throw StateError(
        'The online provider did not return a playable stream URL.',
      );
    }

    final lyricsUrl = _text(
      data['lyricsUrl'] ?? data['lyrics_url'],
    );

    return StreamResponse(
      streamUrl: streamUrl,
      lyricsUrl: lyricsUrl.isEmpty ? null : lyricsUrl,
    );
  }

  Future<Response<dynamic>> _get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    if (Endpoints.baseUrl.isEmpty) {
      throw StateError(
        'Online provider is not configured. '
        'Run with --dart-define=AURORA_API_BASE_URL=<provider-url>.',
      );
    }

    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
      );
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      final message = _dioErrorMessage(error);

      throw Exception(
        status == null
            ? 'Online provider request failed: $message'
            : 'Online provider returned HTTP $status: $message',
      );
    }
  }

  List<OnlineSong> _songList(dynamic body) {
    return _items(body)
        .whereType<Map>()
        .map((item) => OnlineSong.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .where((song) => song.id.isNotEmpty)
        .toList();
  }

  List<dynamic> _items(dynamic body) {
    if (body is List) return body;

    if (body is Map) {
      final map = Map<String, dynamic>.from(body);
      final candidates = <dynamic>[
        map['songs'],
        map['tracks'],
        map['items'],
        map['results'],
        map['data'],
      ];

      for (final candidate in candidates) {
        if (candidate is List) return candidate;
      }
    }

    return const [];
  }

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return const {};
  }

  String _text(dynamic value) {
    return value?.toString().trim() ?? '';
  }

  String _dioErrorMessage(DioException error) {
    final data = error.response?.data;

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final message = map['message'] ?? map['error'] ?? map['detail'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }
    }

    return error.message ?? 'Unknown network error';
  }
}
