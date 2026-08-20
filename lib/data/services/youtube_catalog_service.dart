import 'dart:convert';

import 'package:dio/dio.dart';

/// Client for Aurora's server-side YouTube catalog endpoint.
///
/// The YouTube API key stays on the Aurora backend. The Flutter application
/// only talks to the Aurora HTTPS API.
class YoutubeCatalogService {
  YoutubeCatalogService({
    required Dio dio,
  }) : _dio = dio;

  final Dio _dio;

  Future<List<YoutubeCatalogItem>> search(
    String query, {
    int limit = 10,
  }) async {
    final normalized = query.trim();
    if (normalized.isEmpty) return const [];

    final response = await _dio.get(
      '/v1/providers/youtube/search',
      queryParameters: {
        'q': normalized,
        'limit': limit.clamp(1, 25),
      },
    );

    final data = response.data;
    if (data is! Map) return const [];

    final items = data['items'];
    if (items is! List) return const [];

    return items
        .whereType<Map>()
        .map(YoutubeCatalogItem.fromJson)
        .where((item) => item.videoId.isNotEmpty)
        .toList(growable: false);
  }
}

class YoutubeCatalogItem {
  const YoutubeCatalogItem({
    required this.videoId,
    required this.title,
    required this.channelTitle,
    required this.description,
    required this.thumbnailUrl,
    required this.watchUrl,
    required this.embedUrl,
  });

  final String videoId;
  final String title;
  final String channelTitle;
  final String description;
  final String thumbnailUrl;
  final String watchUrl;
  final String embedUrl;

  factory YoutubeCatalogItem.fromJson(Map value) =>
      YoutubeCatalogItem(
        videoId: '${value['videoId'] ?? ''}'.trim(),
        title: '${value['title'] ?? ''}'.trim(),
        channelTitle: '${value['channelTitle'] ?? ''}'.trim(),
        description: '${value['description'] ?? ''}'.trim(),
        thumbnailUrl: '${value['thumbnailUrl'] ?? ''}'.trim(),
        watchUrl: '${value['watchUrl'] ?? ''}'.trim(),
        embedUrl: '${value['embedUrl'] ?? ''}'.trim(),
      );

  Map<String, dynamic> toJson() => {
        'videoId': videoId,
        'title': title,
        'channelTitle': channelTitle,
        'description': description,
        'thumbnailUrl': thumbnailUrl,
        'watchUrl': watchUrl,
        'embedUrl': embedUrl,
      };

  String encode() => jsonEncode(toJson());
}
