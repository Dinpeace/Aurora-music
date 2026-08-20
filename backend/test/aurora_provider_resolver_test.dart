import 'package:test/test.dart';
import 'package:aurora_cloud_foundation/src/aurora_provider_resolver.dart';

AuroraProviderSource source({
  required String provider,
  required bool available,
  double quality = .5,
  String id = 'aurora-1',
}) =>
    AuroraProviderSource(
      auroraId: id,
      provider: provider,
      providerId: '$provider-1',
      available: available,
      qualityScore: quality,
      title: 'Song',
      artist: 'Artist',
      album: 'Album',
    );

void main() {
  test('preferred available provider wins', () {
    final resolver = AuroraProviderResolver(
      sources: [
        source(provider: 'youtube', available: true, quality: .9),
        source(provider: 'aurora', available: true, quality: .5),
      ],
    );

    final resolved = resolver.resolve('aurora-1');

    expect(resolved, isNotNull);
    expect(resolved!.selected.provider, 'aurora');
  });

  test('unavailable preferred provider falls back to available source', () {
    final resolver = AuroraProviderResolver(
      sources: [
        source(provider: 'aurora', available: false, quality: 1),
        source(provider: 'youtube', available: true, quality: .7),
      ],
    );

    final resolved = resolver.resolve('aurora-1');

    expect(resolved!.selected.provider, 'youtube');
    expect(resolved.hasAvailableSource, isTrue);
  });

  test('quality breaks ties within the same provider', () {
    final resolver = AuroraProviderResolver(
      sources: [
        source(provider: 'licensed', available: true, quality: .4),
        source(provider: 'licensed', available: true, quality: .9),
      ],
      providerPriority: const ['licensed'],
    );

    expect(resolver.resolve('aurora-1')!.selected.qualityScore, .9);
  });

  test('unknown song returns null', () {
    final resolver = AuroraProviderResolver(
      sources: [source(provider: 'youtube', available: true)],
    );

    expect(resolver.resolve('missing'), isNull);
  });

  test('empty provider data round-trips safely', () {
    final value = AuroraProviderSource.fromJson({
      'auroraId': 'a',
      'provider': 'youtube',
      'providerId': 'y',
      'available': false,
      'qualityScore': 0.25,
      'title': 'Song',
      'artist': 'Artist',
      'album': 'Album',
    });

    expect(value.auroraId, 'a');
    expect(value.available, isFalse);
    expect(value.qualityScore, .25);
    expect(value.artworkUrl, isNull);
  });
}
