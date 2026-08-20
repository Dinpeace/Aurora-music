import 'package:dio/dio.dart';

/// Resolves a normalized Aurora catalog song into provider sources through the
/// Aurora cloud API. The server remains responsible for provider credentials
/// and provider-specific logic.
class AuroraProviderResolverService {
  AuroraProviderResolverService({
    required Dio dio,
  }) : _dio = dio;

  final Dio _dio;

  Future<AuroraResolvedSource?> resolve(String auroraId) async {
    final id = auroraId.trim();
    if (id.isEmpty) return null;

    final response = await _dio.get(
      '/v1/catalog/resolve',
      queryParameters: {'id': id},
    );

    if (response.data is! Map) return null;
    return AuroraResolvedSource.fromJson(response.data as Map);
  }
}

class AuroraResolvedSource {
  const AuroraResolvedSource({
    required this.auroraId,
    required this.selectedProvider,
    required this.selectedProviderId,
    required this.available,
    required this.sources,
  });

  final String auroraId;
  final String selectedProvider;
  final String selectedProviderId;
  final bool available;
  final List<AuroraSourceItem> sources;

  factory AuroraResolvedSource.fromJson(Map value) {
    final rawSources = value['sources'];

    return AuroraResolvedSource(
      auroraId: '${value['auroraId'] ?? ''}'.trim(),
      selectedProvider: '${value['selectedProvider'] ?? ''}'.trim(),
      selectedProviderId: '${value['selectedProviderId'] ?? ''}'.trim(),
      available: value['available'] == true,
      sources: rawSources is List
          ? rawSources
              .whereType<Map>()
              .map(AuroraSourceItem.fromJson)
              .toList(growable: false)
          : const [],
    );
  }
}

class AuroraSourceItem {
  const AuroraSourceItem({
    required this.provider,
    required this.providerId,
    required this.available,
    required this.qualityScore,
  });

  final String provider;
  final String providerId;
  final bool available;
  final double qualityScore;

  factory AuroraSourceItem.fromJson(Map value) => AuroraSourceItem(
        provider: '${value['provider'] ?? ''}'.trim(),
        providerId: '${value['providerId'] ?? ''}'.trim(),
        available: value['available'] == true,
        qualityScore: value['qualityScore'] is num
            ? (value['qualityScore'] as num).toDouble()
            : double.tryParse('${value['qualityScore']}') ?? 0,
      );
}
