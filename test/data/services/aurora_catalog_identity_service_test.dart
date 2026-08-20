import 'package:flutter_test/flutter_test.dart';

import 'package:aurora_music/data/services/aurora_catalog_identity_service.dart';

void main() {
  final service = AuroraCatalogIdentityService();

  test('identity is stable for normalized metadata', () {
    final a = service.identity(
      title: 'Midnight Drive (Official Audio)',
      artist: 'Aurora',
      album: 'Night',
    );

    final b = service.identity(
      title: '  MIDNIGHT DRIVE  ',
      artist: 'aurora',
      album: 'night',
    );

    expect(a, b);
  });

  test('different artists produce different identities', () {
    final a = service.identity(
      title: 'Song',
      artist: 'Artist A',
      album: 'Album',
    );

    final b = service.identity(
      title: 'Song',
      artist: 'Artist B',
      album: 'Album',
    );

    expect(a, isNot(b));
  });

  test('bracketed metadata is ignored for identity', () {
    final identity = service.identity(
      title: 'Song [Official Video]',
      artist: 'Artist',
      album: 'Album',
    );

    expect(identity, 'song|artist|album');
  });
}
