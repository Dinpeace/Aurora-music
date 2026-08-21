import 'package:flutter_test/flutter_test.dart';
import 'package:aurora_music/data/services/aurora_cloud_api_client.dart';

class FakeTransport implements AuroraHttpTransport {
  final List<AuroraHttpRequest> requests = [];
  Map<String, dynamic> response = const {};

  @override
  Future<Map<String, dynamic>> request(AuroraHttpRequest request) async {
    requests.add(request);
    return response;
  }
}

AuroraCloudApiClient client(FakeTransport transport) =>
    AuroraCloudApiClient(transport: transport);

void main() {
  test('empty catalog search does not call transport', () async {
    final transport = FakeTransport();

    final result = await client(transport).searchCatalog('  ');

    expect(result.items, isEmpty);
    expect(transport.requests, isEmpty);
  });

  test('catalog search creates the expected GET request', () async {
    final transport = FakeTransport()
      ..response = {
        'items': [
          {
            'id': 'song-1',
            'title': 'Aurora',
            'artist': 'Artist',
            'album': 'Album',
            'durationMs': 180000,
          },
        ],
      };

    final result = await client(transport).searchCatalog('Aurora');

    expect(result.items.single.id, 'song-1');
    expect(transport.requests.single.method, 'GET');
    expect(transport.requests.single.path, '/v1/catalog/search');
    expect(transport.requests.single.query['q'], 'Aurora');
  });

  test('catalog item parses numeric duration safely', () async {
    final transport = FakeTransport()
      ..response = {
        'item': {
          'id': 'song-1',
          'title': 'Song',
          'artist': 'Artist',
          'album': 'Album',
          'durationMs': 123.9,
        },
      };

    final item = await client(transport).getCatalogItem('song-1');

    expect(item!.durationMs, 123);
    expect(transport.requests.single.query['id'], 'song-1');
  });

  test('blank catalog ID returns null without transport', () async {
    final transport = FakeTransport();

    expect(await client(transport).getCatalogItem(' '), isNull);
    expect(transport.requests, isEmpty);
  });

  test('playback resolution parses selected provider', () async {
    final transport = FakeTransport()
      ..response = {
        'auroraId': 'song-1',
        'selectedProvider': 'youtube',
        'selectedProviderId': 'yt-1',
        'available': true,
      };

    final result = await client(transport).resolvePlayback('song-1');

    expect(result!.selectedProvider, 'youtube');
    expect(result.available, isTrue);
  });

  test('profile endpoint parses favorites', () async {
    final transport = FakeTransport()
      ..response = {
        'profile': {
          'userId': 'user-1',
          'displayName': 'Aurora User',
          'favoriteSongIds': ['song-1', 'song-2'],
        },
      };

    final profile = await client(transport).getProfile('user-1');

    expect(profile!.userId, 'user-1');
    expect(profile.favoriteSongIds, ['song-1', 'song-2']);
  });

  test('favorites POST removes empty IDs', () async {
    final transport = FakeTransport();

    await client(transport).updateFavorites(
      userId: 'user-1',
      songIds: const [' song-1 ', '', 'song-2'],
    );

    final request = transport.requests.single;
    expect(request.method, 'POST');
    expect(request.path, '/v1/user/favorites');
    expect(request.body!['userId'], 'user-1');
    expect(request.body!['songIds'], ['song-1', 'song-2']);
  });

  test('playlist response is typed', () async {
    final transport = FakeTransport()
      ..response = {
        'playlist': {
          'id': 'p1',
          'name': 'Favorites',
          'songIds': ['song-1'],
        },
      };

    final playlist = await client(transport).savePlaylist(
      userId: 'user-1',
      playlist: const AuroraApiPlaylist(
        id: 'p1',
        name: 'Favorites',
        songIds: ['song-1'],
      ),
    );

    expect(playlist.id, 'p1');
    expect(playlist.songIds, ['song-1']);
  });

  test('missing playlist response throws typed API error', () async {
    final transport = FakeTransport();

    expect(
      () => client(transport).savePlaylist(
        userId: 'user-1',
        playlist: const AuroraApiPlaylist(
          id: 'p1',
          name: 'Favorites',
        ),
      ),
      throwsA(
        isA<AuroraApiException>().having(
          (error) => error.error,
          'error',
          AuroraApiError.invalidResponse,
        ),
      ),
    );
  });

  test('history POST serializes UTC timestamps', () async {
    final transport = FakeTransport();

    await client(transport).appendHistory(
      userId: 'user-1',
      events: [
        AuroraApiHistoryEvent(
          songId: 'song-1',
          playedAt: DateTime.utc(2026, 1, 1, 10),
          positionMs: 5000,
          completed: true,
        ),
      ],
    );

    final body = transport.requests.single.body!;
    final events = body['events'] as List;
    final event = events.single as Map<String, dynamic>;

    expect(event['songId'], 'song-1');
    expect(event['positionMs'], 5000);
    expect(event['completed'], isTrue);
    expect(event['playedAt'], '2026-01-01T10:00:00.000Z');
  });
}
