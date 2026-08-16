import 'package:flutter_test/flutter_test.dart';

import 'update_service.dart';

void main() {
  test('detects a newer patch version', () {
    expect(UpdateService.isVersionNewer('1.0.1', '1.0.0'), isTrue);
  });

  test('detects a newer major version with a v prefix', () {
    expect(UpdateService.isVersionNewer('v2.0.0', '1.9.9'), isTrue);
  });

  test('does not flag the same version', () {
    expect(UpdateService.isVersionNewer('v1.0.0', '1.0.0'), isFalse);
  });

  test('does not flag an older release', () {
    expect(UpdateService.isVersionNewer('0.9.9', '1.0.0'), isFalse);
  });

  test('accepts missing patch components', () {
    expect(UpdateService.isVersionNewer('1.1', '1.0.9'), isTrue);
  });
}
