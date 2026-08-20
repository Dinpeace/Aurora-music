import 'package:flutter_test/flutter_test.dart';

import 'package:aurora_music/data/services/aurora_online_configuration.dart';

void main() {
  test('production configuration accepts a remote HTTPS API', () {
    const config = AuroraOnlineConfiguration(
      baseUrl: 'https://api.example.com',
      production: true,
    );

    expect(config.isConfigured, isTrue);
    expect(config.isLocalhost, isFalse);
    expect(config.productionSafe, isTrue);
    expect(() => config.assertReady(), returnsNormally);
  });

  test('production configuration rejects localhost', () {
    const config = AuroraOnlineConfiguration(
      baseUrl: 'http://127.0.0.1:8080',
      production: true,
    );

    expect(config.isLocalhost, isTrue);
    expect(config.productionSafe, isFalse);
    expect(
      () => config.assertReady(),
      throwsA(isA<StateError>()),
    );
  });

  test('development configuration may use localhost', () {
    const config = AuroraOnlineConfiguration(
      baseUrl: 'http://localhost:8080',
    );

    expect(config.isConfigured, isTrue);
    expect(config.isLocalhost, isTrue);
    expect(config.productionSafe, isTrue);
  });

  test('empty production URL is rejected', () {
    const config = AuroraOnlineConfiguration(
      baseUrl: '',
      production: true,
    );

    expect(
      () => config.assertReady(),
      throwsA(isA<StateError>()),
    );
  });
}
