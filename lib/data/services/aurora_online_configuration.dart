import '../models/online/online_song.dart';
import '../../core/provider/music_provider.dart';

/// Production-safe provider configuration helper.
///
/// The existing ProviderClient already uses AURORA_API_BASE_URL through
/// Endpoints. This value object gives the application a single place to
/// validate that production is not accidentally pointed at localhost.
class AuroraOnlineConfiguration {
  const AuroraOnlineConfiguration({
    required this.baseUrl,
    this.production = false,
  });

  final String baseUrl;
  final bool production;

  bool get isConfigured => baseUrl.trim().isNotEmpty;

  bool get isLocalhost {
    final value = baseUrl.trim().toLowerCase();
    return value.contains('localhost') ||
        value.contains('127.0.0.1') ||
        value.contains('0.0.0.0');
  }

  bool get productionSafe => !production || (isConfigured && !isLocalhost);

  void assertReady() {
    if (!isConfigured) {
      throw StateError('Aurora online API URL is not configured.');
    }
    if (!productionSafe) {
      throw StateError(
        'Production Aurora must not use a localhost API URL.',
      );
    }
  }
}

/// Small adapter contract for future cloud-backed repository implementations.
abstract class AuroraCloudCatalog {
  Future<List<OnlineSong>> search(String query);

  Future<List<OnlineSong>> trending();

  Future<List<OnlineSong>> recommendations();

  Future<String> streamUrl(String songId);

  Future<String?> lyrics(String songId);
}

/// Keeps the existing MusicProvider architecture compatible with the
/// production cloud catalog contract.
class AuroraCloudMusicProvider implements MusicProvider {
  AuroraCloudMusicProvider(this.catalog);

  final AuroraCloudCatalog catalog;

  @override
  Future<List<OnlineSong>> search(String query) => catalog.search(query);

  @override
  Future<List<OnlineSong>> trending() => catalog.trending();

  @override
  Future<List<OnlineSong>> recommendations() =>
      catalog.recommendations();

  @override
  Future<String> streamUrl(String songId) => catalog.streamUrl(songId);

  @override
  Future<String?> lyrics(String songId) => catalog.lyrics(songId);
}
