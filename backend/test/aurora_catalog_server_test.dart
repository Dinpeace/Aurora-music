import 'dart:io';

import 'package:test/test.dart';
import 'package:aurora_cloud_foundation/src/aurora_catalog_server.dart';

AuroraCatalogSong song({
  String id = 'one',
  String title = 'Aurora',
  String artist = 'Aurora Artist',
  double popularity = .5,
}) =>
    AuroraCatalogSong(
      id: id,
      title: title,
      artist: artist,
      album: 'Album',
      genres: const ['pop'],
      durationMs: 180000,
      artworkUrl: 'https://example.com/art.jpg',
      provider: 'youtube',
      providerId: id,
      popularity: popularity,
    );

void main() {
  test('search matches title and artist', () {
    final repo = AuroraCatalogRepository([
      song(),
      song(
        id: 'two',
        title: 'Other',
        artist: 'Aurora Artist',
      ),
    ]);

    expect(repo.search('Aurora'), hasLength(2));
    expect(repo.search('Other').single.id, 'two');
  });

  test('trending sorts by popularity', () {
    final repo = AuroraCatalogRepository([
      song(id: 'low', popularity: .2),
      song(id: 'high', popularity: .9),
    ]);

    expect(repo.trending().first.id, 'high');
  });

  test('upsert and remove work by stable catalog ID', () {
    final repo = AuroraCatalogRepository();

    repo.upsert(song(id: 'x'));
    expect(repo.get('x'), isNotNull);
    expect(repo.remove('x'), isTrue);
    expect(repo.get('x'), isNull);
  });

  test('HTTP search endpoint returns catalog items', () async {
    final server = AuroraCatalogServer(
      repository: AuroraCatalogRepository([song()]),
      host: InternetAddress.loopbackIPv4,
      port: 48124,
    );
    await server.start();

    final client = HttpClient();
    final request = await client.getUrl(
      Uri.parse(
        'http://127.0.0.1:48124/v1/catalog/search?q=Aurora',
      ),
    );
    final response = await request.close();
    final body = await response.transform(const SystemEncoding().decoder).join();

    expect(response.statusCode, 200);
    expect(body, contains('"id":"one"'));

    client.close(force: true);
    await server.stop();
  });

  test('HTTP song endpoint returns 404 for unknown IDs', () async {
    final server = AuroraCatalogServer(
      repository: AuroraCatalogRepository(),
      host: InternetAddress.loopbackIPv4,
      port: 48125,
    );
    await server.start();

    final client = HttpClient();
    final request = await client.getUrl(
      Uri.parse(
        'http://127.0.0.1:48125/v1/catalog/song?id=missing',
      ),
    );
    final response = await request.close();

    expect(response.statusCode, 404);

    client.close(force: true);
    await server.stop();
  });
}
