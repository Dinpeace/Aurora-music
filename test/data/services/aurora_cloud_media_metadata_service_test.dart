import 'package:flutter_test/flutter_test.dart';
import 'package:aurora_music/data/services/aurora_cloud_media_metadata_service.dart';

class FakeGateway implements AuroraMediaMetadataGateway {
  AuroraUnifiedTrackMetadata? metadata;
  int calls = 0;

  @override
  Future<AuroraUnifiedTrackMetadata?> fetchTrack(String auroraId) async {
    calls++;
    return metadata;
  }
}

class FixedClock extends AuroraMetadataClock {
  const FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}

AuroraUnifiedTrackMetadata metadata({
  required DateTime updatedAt,
}) =>
    AuroraUnifiedTrackMetadata(
      auroraId: 'aurora-1',
      title: 'Aurora',
      artist: 'Artist',
      album: 'Album',
      albumArtist: 'Artist',
      durationMs: 180000,
      updatedAt: updatedAt,
      genres: const ['pop'],
      moods: const ['calm'],
      explicit: false,
      metadataVersion: 2,
      artwork: const AuroraArtworkMetadata(
        url: 'https://example.com/art.jpg',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        width: 1000,
        height: 1000,
        source: 'cloud',
      ),
      lyrics: const AuroraLyricsMetadata(
        available: true,
        url: 'https://example.com/lyrics',
        language: 'en',
        synced: true,
        provider: 'cloud',
      ),
      source: const AuroraProviderSourceMetadata(
        provider: 'youtube',
        providerId: 'source-1',
        available: true,
        quality: 'high',
        mimeType: 'audio/mpeg',
      ),
    );

void main() {
  test('empty ID is a safe no-op', () async {
    final gateway = FakeGateway();

    final result = await AuroraCloudMediaMetadataService(
      gateway: gateway,
    ).getTrack('  ');

    expect(result, isNull);
    expect(gateway.calls, 0);
  });

  test('fetches and caches fresh metadata', () async {
    final gateway = FakeGateway()
      ..metadata = metadata(
        updatedAt: DateTime.utc(2026, 1, 1, 12),
      );
    final cache = AuroraMemoryMediaMetadataCache();

    final service = AuroraCloudMediaMetadataService(
      gateway: gateway,
      cache: cache,
      clock: FixedClock(DateTime.utc(2026, 1, 1, 13)),
    );

    final first = await service.getTrack('aurora-1');
    final second = await service.getTrack('aurora-1');

    expect(first!.auroraId, 'aurora-1');
    expect(second!.title, 'Aurora');
    expect(gateway.calls, 1);
  });

  test('stale cached metadata is refreshed', () async {
    final gateway = FakeGateway()
      ..metadata = metadata(
        updatedAt: DateTime.utc(2026, 1, 2),
      );
    final cache = AuroraMemoryMediaMetadataCache();

    await cache.put(
      'track:aurora-1',
      metadata(updatedAt: DateTime.utc(2025, 12, 31)),
    );

    final service = AuroraCloudMediaMetadataService(
      gateway: gateway,
      cache: cache,
      clock: FixedClock(DateTime.utc(2026, 1, 2)),
    );

    final result = await service.getTrack('aurora-1');

    expect(result!.updatedAt, DateTime.utc(2026, 1, 2));
    expect(gateway.calls, 1);
  });

  test('cache can be bypassed', () async {
    final gateway = FakeGateway()
      ..metadata = metadata(
        updatedAt: DateTime.utc(2026, 1, 1),
      );
    final cache = AuroraMemoryMediaMetadataCache();

    await cache.put(
      'track:aurora-1',
      metadata(updatedAt: DateTime.utc(2026, 1, 1)),
    );

    final service = AuroraCloudMediaMetadataService(
      gateway: gateway,
      cache: cache,
    );

    await service.getTrack('aurora-1', useCache: false);

    expect(gateway.calls, 1);
  });

  test('artwork metadata is exposed through the service', () async {
    final gateway = FakeGateway()
      ..metadata = metadata(
        updatedAt: DateTime.now(),
      );

    final artwork = await AuroraCloudMediaMetadataService(
      gateway: gateway,
    ).getArtwork('aurora-1');

    expect(artwork!.url, 'https://example.com/art.jpg');
    expect(artwork.width, 1000);
  });

  test('lyrics metadata is exposed through the service', () async {
    final gateway = FakeGateway()
      ..metadata = metadata(
        updatedAt: DateTime.now(),
      );

    final lyrics = await AuroraCloudMediaMetadataService(
      gateway: gateway,
    ).getLyrics('aurora-1');

    expect(lyrics!.available, isTrue);
    expect(lyrics.synced, isTrue);
    expect(lyrics.language, 'en');
  });

  test('provider source metadata is exposed through the service', () async {
    final gateway = FakeGateway()
      ..metadata = metadata(
        updatedAt: DateTime.now(),
      );

    final source = await AuroraCloudMediaMetadataService(
      gateway: gateway,
    ).getSource('aurora-1');

    expect(source!.provider, 'youtube');
    expect(source.providerId, 'source-1');
    expect(source.available, isTrue);
  });

  test('metadata stale calculation is deterministic', () {
    final value = metadata(updatedAt: DateTime.utc(2026, 1, 1));

    expect(
      value.isStale(
        DateTime.utc(2026, 1, 1, 23),
      ),
      isFalse,
    );
    expect(
      value.isStale(
        DateTime.utc(2026, 1, 2, 1),
      ),
      isTrue,
    );
  });

  test('metadata exposes a stable cache key', () {
    final value = metadata(updatedAt: DateTime.utc(2026, 1, 1));

    expect(value.cacheKey, 'track:aurora-1');
  });

  test('invalidate removes cached metadata', () async {
    final gateway = FakeGateway()
      ..metadata = metadata(updatedAt: DateTime.now());
    final cache = AuroraMemoryMediaMetadataCache();

    final service = AuroraCloudMediaMetadataService(
      gateway: gateway,
      cache: cache,
    );

    await service.getTrack('aurora-1');
    await service.invalidate('aurora-1');
    await service.getTrack('aurora-1');

    expect(gateway.calls, 2);
  });

  test('missing gateway metadata returns null', () async {
    final gateway = FakeGateway();

    final result = await AuroraCloudMediaMetadataService(
      gateway: gateway,
    ).getTrack('missing');

    expect(result, isNull);
    expect(gateway.calls, 1);
  });
}
