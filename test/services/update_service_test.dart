import 'package:flutter_test/flutter_test.dart';
import 'package:aurora_music/core/services/update_service.dart';

void main() {
  group('UpdateService version comparison', () {
    test('detects a newer patch version', () {
      expect(UpdateService.isVersionNewer('1.0.1', '1.0.0'), isTrue);
    });

    test('detects a newer minor version', () {
      expect(UpdateService.isVersionNewer('1.1.0', '1.0.0'), isTrue);
    });

    test('detects a newer major version', () {
      expect(UpdateService.isVersionNewer('2.0.0', '1.9.9'), isTrue);
    });

    test('does not report the same version as newer', () {
      expect(UpdateService.isVersionNewer('1.0.0', '1.0.0'), isFalse);
    });

    test('does not report an older version as newer', () {
      expect(UpdateService.isVersionNewer('0.9.9', '1.0.0'), isFalse);
    });

    test('handles v-prefixed versions', () {
      expect(UpdateService.isVersionNewer('v1.0.1', 'v1.0.0'), isTrue);
    });
  });
}
