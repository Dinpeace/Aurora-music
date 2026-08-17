
import 'package:flutter_test/flutter_test.dart';

import 'package:aurora_music/data/services/listening_intelligence_events.dart';

void main() {
  test('emits a change event when intelligence changes', () async {
    final events = ListeningIntelligenceEvents.instance;
    final future = events.changes.first;

    events.notifyChanged();

    await expectLater(future, completion(isNull));
  });
}
