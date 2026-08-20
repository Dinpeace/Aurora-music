import 'dart:convert';
import 'dart:io';

/// YouTube catalog adapter for the Aurora Cloud API.
///
/// IMPORTANT:
/// This adapter uses the official YouTube Data API for metadata/search.
/// It does not extract, download, proxy, or expose raw YouTube audio streams.
/// Playback of YouTube content should use an allowed YouTube playback surface.
class YoutubeCatalogAdapter {
  YoutubeCatalogAdapter({
    required this.apiKey,
    HttpClient? httpClient,
  }) : _httpClient = httpClient ?? HttpClient();

  final String apiKey;
  final HttpClient _httpClient;

  Future<List<YoutubeVideoResult>> search(
    String query, {
    int maxResults = 10,
    String regionCode = 'IN',
  }) async {
    final normalized = query.trim();
    if (normalized.isEmpty) return const [];

    final uri = Uri.https(
      'www.googleapis.com',
      '/youtube/v3/search',
      <String, String>{
        'part': 'snippet',
        'q': normalized,
        'type': 'video',
        'maxResults': '${maxResults.clamp(1, 25)}',
        'regionCode': regionCode,
        'key': apiKey,
      },
    );

    final request = await _httpClient.getUrl(uri);
    final response = await request.close();
    final body =
        await response.transform(utf8.decoder).join();

    if (response.statusCode != 200) {
      throw HttpException(
        'YouTube Data API returned HTTP ${response.statusCode}.',
      );
    }

    final decoded = jsonDecode(body);
    if (decoded is! Map) return const [];

    final items = decoded['items'];
    if (items is! List) return const [];

    return items
        .whereType<Map>()
        .map(YoutubeVideoResult.fromJson)
        .where((item) => item.videoId.isNotEmpty)
        .toList(growable: false);
  }

  void close() {
    _httpClient.close(force: true);
  }
}

class YoutubeVideoResult {
  const YoutubeVideoResult({
    required this.videoId,
    required this.title,
    required this.channelTitle,
    required this.description,
    required this.thumbnailUrl,
  });

  final String videoId;
  final String title;
  final String channelTitle;
  final String description;
  final String thumbnailUrl;

  String get watchUrl => 'https://www.youtube.com/watch?v=$videoId';

  String get embedUrl =>
      'https://www.youtube.com/embed/$videoId';

  factory YoutubeVideoResult.fromJson(Map value) {
    final id = value['id'];
    final snippet = value['snippet'];

    final videoId = id is Map
        ? '${id['videoId'] ?? ''}'.trim()
        : '';

    final map = snippet is Map
        ? Map<String, dynamic>.from(snippet)
        : const <String, dynamic>{};

    final thumbnails = map['thumbnails'];
    final thumbnail = thumbnails is Map
        ? thumbnails['high'] ?? thumbnails['medium'] ?? thumbnails['default']
        : null;

    final thumbnailMap = thumbnail is Map
        ? Map<String, dynamic>.from(thumbnail)
        : const <String, dynamic>{};

    return YoutubeVideoResult(
      videoId: videoId,
      title: '${map['title'] ?? ''}'.trim(),
      channelTitle: '${map['channelTitle'] ?? ''}'.trim(),
      description: '${map['description'] ?? ''}'.trim(),
      thumbnailUrl: '${thumbnailMap['url'] ?? ''}'.trim(),
    );
  }
}
