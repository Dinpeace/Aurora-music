import 'dart:io';

import 'package:test/test.dart';

import 'package:aurora_cloud_foundation/src/aurora_cloud_server.dart';

void main() {
  late AuroraCloudServer server;

  setUp(() async {
    server = AuroraCloudServer(
      host: InternetAddress.loopbackIPv4,
      port: 48123,
    );
    await server.start();
  });

  tearDown(() => server.stop());

  test('health endpoint reports the Aurora API as alive', () async {
    final client = HttpClient();

    final request = await client.getUrl(
      Uri.parse('http://127.0.0.1:48123/health'),
    );
    final response = await request.close();
    final body = await response.transform(const SystemEncoding().decoder).join();

    expect(response.statusCode, 200);
    expect(body, contains('"status":"ok"'));

    client.close(force: true);
  });

  test('search endpoint is online-ready and deterministic', () async {
    final client = HttpClient();

    final request = await client.getUrl(
      Uri.parse(
        'http://127.0.0.1:48123/v1/catalog/search?q=Aurora',
      ),
    );
    final response = await request.close();
    final body = await response.transform(const SystemEncoding().decoder).join();

    expect(response.statusCode, 200);
    expect(body, contains('"query":"Aurora"'));
    expect(body, contains('"songs":[]'));

    client.close(force: true);
  });

  test('song endpoint rejects an empty ID', () async {
    final client = HttpClient();

    final request = await client.getUrl(
      Uri.parse('http://127.0.0.1:48123/v1/catalog/song'),
    );
    final response = await request.close();
    final body = await response.transform(const SystemEncoding().decoder).join();

    expect(response.statusCode, 400);
    expect(body, contains('song_id_required'));

    client.close(force: true);
  });
}
