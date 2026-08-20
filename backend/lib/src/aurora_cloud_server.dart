import 'dart:convert';
import 'dart:io';

/// Aurora Cloud Foundation v1.
///
/// This is a dependency-free HTTP contract skeleton for the production
/// backend. It deliberately does not embed a database driver or cloud vendor.
/// The Flutter app can use the same API contract in development and production.
class AuroraCloudServer {
  AuroraCloudServer({
    required this.host,
    required this.port,
  });

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

    try {
      final path = request.uri.path;

      if (request.method == 'GET' && path == '/health') {
        await _json(
          request,
          200,
          {
            'status': 'ok',
            'service': 'aurora-api',
            'version': 1,
          },
        );
        return;
      }

      if (request.method == 'GET' && path == '/v1/catalog/search') {
        final query = request.uri.queryParameters['q']?.trim() ?? '';
        await _json(
          request,
          200,
          {
            'query': query,
            'songs': <Map<String, dynamic>>[],
            'artists': <Map<String, dynamic>>[],
            'albums': <Map<String, dynamic>>[],
          },
        );
        return;
      }

      if (request.method == 'GET' && path == '/v1/catalog/trending') {
        await _json(
          request,
          200,
          {'songs': <Map<String, dynamic>>[]},
        );
        return;
      }

      if (request.method == 'GET' && path == '/v1/catalog/recommendations') {
        await _json(
          request,
          200,
          {'songs': <Map<String, dynamic>>[]},
        );
        return;
      }

      if (request.method == 'GET' && path == '/v1/catalog/song') {
        final id = request.uri.queryParameters['id']?.trim() ?? '';

        if (id.isEmpty) {
          await _json(
            request,
            400,
            {'error': 'song_id_required'},
          );
          return;
        }

        await _json(
          request,
          200,
          {
            'id': id,
            'streamUrl': null,
            'lyricsUrl': null,
          },
        );
        return;
      }

      await _json(
        request,
        404,
        {'error': 'not_found'},
      );
    } catch (_) {
      await _json(
        request,
        500,
        {'error': 'internal_server_error'},
      );
    }
  }

  Future<void> _json(
    HttpRequest request,
    int status,
    Map<String, dynamic> body,
  ) async {
    request.response.statusCode = status;
    request.response.write(jsonEncode(body));
    await request.response.close();
  }
}
