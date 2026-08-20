import 'package:test/test.dart';
import 'package:aurora_cloud_foundation/src/aurora_catalog_matcher.dart';

AuroraRawMetadata metadata({
  String title = 'Midnight Drive',
  String artist = 'Aurora',
  String album = 'Night',
  int durationMs = 180000,
}) =>
    AuroraRawMetadata(
      title: title,
      artist: artist,
      album: album,
      durationMs: durationMs,
    );

void main() {
  final matcher = AuroraCatalogMatcher();

  test('normalization removes common parenthetical suffixes', () {
    final result = matcher.normalize(
      metadata(title: 'Midnight Drive (Official Audio)'),
    );

    expect(result.title, 'midnight drive');
    expect(result.key, 'midnightdrive|aurora|night');
  });

  test('identical metadata has an exact key match', () {
    final a = matcher.normalize(metadata());
    final b = matcher.normalize(metadata());

    final result = matcher.match(a, b);

    expect(result.exactKeyMatch, isTrue);
    expect(result.matched, isTrue);
    expect(result.score, 1.0);
  });

  test('minor title differences can still match', () {
    final a = matcher.normalize(metadata());
    final b = matcher.normalize(
      metadata(title: 'Midnight Drive - Official'),
    );

    final result = matcher.match(a, b, threshold: .75);

    expect(result.matched, isTrue);
    expect(result.score, greaterThan(.75));
  });

  test('different songs produce a lower score', () {
    final a = matcher.normalize(metadata());
    final b = matcher.normalize(
      metadata(
        title: 'Ocean Lights',
        artist: 'Different Artist',
        album: 'Different Album',
        durationMs: 240000,
      ),
    );

    final result = matcher.match(a, b);

    expect(result.matched, isFalse);
    expect(result.score, lessThan(.82));
  });

  test('duration tolerance is deterministic', () {
    final a = matcher.normalize(metadata(durationMs: 180000));
    final b = matcher.normalize(metadata(durationMs: 181500));

    expect(matcher.similarity(a, b), closeTo(1, .0001));
  });

  test('negative duration is normalized to zero', () {
    final result = matcher.normalize(metadata(durationMs: -1));

    expect(result.durationMs, 0);
  });
}
