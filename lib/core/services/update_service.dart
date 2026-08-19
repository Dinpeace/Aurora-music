import 'dart:convert';

import 'package:dio/dio.dart';

class UpdateInfo {
  const UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseUrl,
    required this.changelog,
  });

  final String currentVersion;
  final String latestVersion;
  final String releaseUrl;
  final String changelog;

  bool get isUpdateAvailable =>
      UpdateService.isVersionNewer(latestVersion, currentVersion);
}

class UpdateService {
  UpdateService({Dio? dio}) : _dio = dio ?? Dio();

  static const owner = 'Dinpeace';
  static const repository = 'Aurora-music';
  static const latestReleaseUrl =
      'https://api.github.com/repos/$owner/$repository/releases/latest';
  static const releasesPageUrl =
      'https://github.com/$owner/$repository/releases';

  final Dio _dio;

  Future<UpdateInfo> checkForUpdates({
    required String currentVersion,
  }) async {
    final response = await _dio.get<Object?>(
      latestReleaseUrl,
      options: Options(
        responseType: ResponseType.json,
        headers: const {'Accept': 'application/vnd.github+json'},
        sendTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
      ),
    );

    final data = response.data is String
        ? jsonDecode(response.data! as String)
        : response.data;

    if (data is! Map) {
      throw const FormatException('Invalid GitHub release response.');
    }

    final tag = data['tag_name']?.toString().trim() ?? '';
    if (tag.isEmpty) {
      throw const FormatException('GitHub release has no tag.');
    }

    final latestVersion = _normalizeVersion(tag);
    final releaseUrl = data['html_url']?.toString().trim();
    final changelog = data['body']?.toString().trim() ?? '';

    return UpdateInfo(
      currentVersion: _normalizeVersion(currentVersion),
      latestVersion: latestVersion,
      releaseUrl: releaseUrl?.isNotEmpty == true
          ? releaseUrl!
          : releasesPageUrl,
      changelog: changelog,
    );
  }

  static String _normalizeVersion(String value) {
    var normalized = value.trim();
    if (normalized.startsWith('v') || normalized.startsWith('V')) {
      normalized = normalized.substring(1);
    }
    return normalized;
  }

  static bool isVersionNewer(String latest, String current) {
    final latestParts = _parseVersion(_normalizeVersion(latest));
    final currentParts = _parseVersion(_normalizeVersion(current));

    for (var i = 0; i < 3; i++) {
      if (latestParts[i] != currentParts[i]) {
        return latestParts[i] > currentParts[i];
      }
    }
    return false;
  }

  static List<int> _parseVersion(String value) {
    final match = RegExp(r'^\d+(?:\.\d+){0,2}').firstMatch(value);
    final parts = (match?.group(0) ?? '0')
        .split('.')
        .map((part) => int.tryParse(part) ?? 0)
        .toList();

    while (parts.length < 3) {
      parts.add(0);
    }

    return parts.take(3).toList(growable: false);
  }
}
