import 'package:flutter_test/flutter_test.dart';

import 'package:aurora_music/data/services/aurora_provider_resolver_service.dart';

void main() {
  test('resolved source parses provider and selected source', () {
    final result = AuroraResolvedSource.fromJson({
      'auroraId': 'aurora-1',
      'selectedProvider': 'aurora',
      'selectedProviderId': 'source-1',
      'available': true,
      'sources': [
        {
          'provider': 'aurora',
          'providerId': 'source-1',
          'available': true,
          'qualityScore': 0.9,
        },
        {
          'provider': 'youtube',
          'providerId': 'yt-1',
          'available': true,
          'qualityScore': 0.7,
        },
      ],
    });

    expect(result.auroraId, 'aurora-1');
    expect(result.selectedProvider, 'aurora');
    expect(result.available, isTrue);
    expect(result.sources, hasLength(2));
    expect(result.sources.first.qualityScore, closeTo(.9, .0001));
  });

  test('missing source list becomes empty', () {
    final result = AuroraResolvedSource.fromJson({
      'auroraId': 'a',
    });

    expect(result.sources, isEmpty);
    expect(result.available, isFalse);
  });

  test('source parser safely converts numeric quality', () {
    final source = AuroraSourceItem.fromJson({
      'provider': 'youtube',
      'providerId': 'y',
      'available': true,
      'qualityScore': 1,
    });

    expect(source.qualityScore, 1.0);
  });
}
