import 'package:flutter_test/flutter_test.dart';
import 'package:aurora_music/data/models/song.dart';
import 'package:aurora_music/data/services/predictive_queue_intent_service.dart';
import 'package:aurora_music/data/services/session_intelligence_service.dart';
import 'package:aurora_music/data/services/smart_queue_service.dart';

void main() {
  Song song(String id, {String artist = 'Aurora'}) => Song(
        id: id, title: id, artist: artist, album: 'Album', artwork: '',
        audioUrl: 'https://example.com/$id.mp3',
        duration: const Duration(minutes: 3),
      );

  test('waits for enough evidence', () {
    final s = SessionIntelligenceService();
    final p = PredictiveQueueIntentService(session: s);
    s.recordPlay(song('one'));
    s.recordSkip('one');
    expect(p.predict(), ListeningMode.balanced);
    expect(p.confidence, 0.0);
  });

  test('rising skips predict discovery', () {
    final s = SessionIntelligenceService();
    final p = PredictiveQueueIntentService(session: s);
    for (var i = 0; i < 3; i++) {
      final id = 'skip-$i';
      s.recordPlay(song(id));
      s.recordSkip(id);
    }
    s.recordPlay(song('four'));
    expect(p.predict(), ListeningMode.discovery);
    expect(p.confidence, greaterThanOrEqualTo(0.55));
  });

  test('concentrated successful listening predicts favorites', () {
    final s = SessionIntelligenceService();
    final p = PredictiveQueueIntentService(session: s);
    for (var i = 0; i < 5; i++) {
      s.recordPlay(song('play-$i', artist: 'Aurora'));
    }
    expect(p.predict(), ListeningMode.favorites);
  });

  test('reset clears prediction but not session history', () {
    final s = SessionIntelligenceService();
    final p = PredictiveQueueIntentService(session: s);
    for (var i = 0; i < 5; i++) {
      s.recordPlay(song('play-$i', artist: 'Aurora'));
    }
    p.predict();
    p.reset();
    expect(p.predictedMode, ListeningMode.balanced);
    expect(p.confidence, 0.0);
    expect(s.playedCount, 5);
  });
}
