import 'dart:convert';
import 'dart:io';

/// In-memory catalog contract for the Aurora Cloud API.
///
/// This is deliberately storage-agnostic. A production deployment can replace
/// the repository implementation with PostgreSQL/Firestore/etc. without
/// changing the HTTP contract.
class AuroraCatalogRepository {
  AuroraCatalogRepository([Iterable<AuroraCatalogSong> songs = const []])
      : _songs = {
          for (final song in songs) song.id: song,
        };

  final Map<String, AuroraCatalogSong> _songs;

  List<AuroraCatalogSong> search(String query, {int limit = 20}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];

    final matches = _songs.values.where((song) {
      return song.title.toLowerCase().contains(q) ||
          song.artist.toLowerCase().contains(q) ||
          song.album.toLowerCase().contains(q) ||
          song.genres.any((genre) => genre.toLowerCase().contains(q));
    }).toList();

    matches.sort((a, b) {
      final aExact = a.title.toLowerCase() == q ? 0 : 1;
      final bExact = b.title.toLowerCase() == q ? 0 : 1;
      return aExact.compareTo(bExact);
    });

    return List.unmodifiable(matches.take(limit.clamp(1, 100)));
  }

  AuroraCatalogSong? get(String id) => _songs[id.trim()];

  List<AuroraCatalogSong> trending({int limit = 20}) {
    final values = _songs.values.toList()
      ..sort((a, b) => b.popularity.compareTo(a.popularity));
    return List.unmodifiable(values.take(limit.clamp(1, 100)));
  }

  void upsert(AuroraCatalogSong song) => _songs[song.id] = song;

  bool remove(String id) => _songs.remove(id.trim()) != null;
}

class AuroraCatalogSong {
  const AuroraCatalogSong({
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

  factory AuroraCatalogSong.fromJson(Map value) {
    final genresValue = value['genres'];
    final genres = genresValue is List
        ? genresValue.whereType<String>().toList(growable: false)
        : const <String>[];

    return AuroraCatalogSong(
      id: '${value['id'] ?? ''}'.trim(),
      title: '${value['title'] ?? ''}'.trim(),
      artist: '${value['artist'] ?? ''}'.trim(),
      album: '${value['album'] ?? ''}'.trim(),
      genres: genres,
      durationMs: _safeInt(value['durationMs']),
      artworkUrl: '${value['artworkUrl'] ?? ''}'.trim(),
      provider: '${value['provider'] ?? ''}'.trim(),
      providerId: '${value['providerId'] ?? ''}'.trim(),
      popularity: _safeDouble(value['popularity']),
      streamUrl: _nullable(value['streamUrl']),
      lyricsUrl: _nullable(value['lyricsUrl']),
    );
  }
}

int _safeInt(dynamic value) => value is num ? value.toInt() : int.tryParse('$value') ?? 0;

double _safeDouble(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

String? _nullable(dynamic value) =>
    value is String && value.trim().isNotEmpty ? value.trim() : null;

/// Minimal HTTP API around the catalog repository.
class AuroraCatalogServer {
  AuroraCatalogServer({
    required this.repository,
    required this.host,
    required this.port,
  });

  final AuroraCatalogRepository repository;
  final InternetAddress host;
  final int port;

  HttpServer? _server;

  Future<void> start() async {
    if (_server != null) return;
    _server = await HttpServer.bind(host, port);

    await for (final request in _server!) {
      await _handle(request);
    }
  }

  Future<void> stop() async {
    final server = _server;
    _server = null;
    await server?.close(force: true);
  }

  Future<void> _handle(HttpRequest request) async {
    request.response.headers.contentType = ContentType.json;
    final path = request.uri.path;

    if (request.method == 'GET' && path == '/v1/catalog/search') {
      final query = request.uri.queryParameters['q'] ?? '';
      await _write(
        request,
        200,
        {
          'items': repository.search(query).map((x) => x.toJson()).toList(),
        },
      );
      return;
    }

    if (request.method == 'GET' && path == '/v1/catalog/trending') {
      await _write(
        request,
        200,
        {
          'items': repository.trending().map((x) => x.toJson()).toList(),
        },
      );
      return;
    }

    if (request.method == 'GET' && path == '/v1/catalog/song') {
      final id = request.uri.queryParameters['id'] ?? '';
      final song = repository.get(id);

      if (song == null) {
        await _write(request, 404, {'error': 'song_not_found'});
        return;
      }

      await _write(request, 200, song.toJson());
      return;
    }

    await _write(request, 404, {'error': 'not_found'});
  }

  Future<void> _write(
    HttpRequest request,
    int status,
    Map<String, dynamic> body,
  ) async {
    request.response.statusCode = status;
    request.response.write(jsonEncode(body));
    await request.response.close();
  }
}
