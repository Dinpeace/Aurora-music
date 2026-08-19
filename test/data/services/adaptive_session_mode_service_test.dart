import 'package:flutter_test/flutter_test.dart';
import 'package:aurora_music/data/models/song.dart';
import 'package:aurora_music/data/services/adaptive_session_mode_service.dart';
import 'package:aurora_music/data/services/session_intelligence_service.dart';
import 'package:aurora_music/data/services/smart_queue_service.dart';

void main() {
  Song song(String id, {String artist = 'Aurora'}) => Song(
        id: id,
        title: id,
        artist: artist,
        album: 'Album',
        artwork: '',
        audioUrl: 'https://example.com/$id.mp3',
        duration: const Duration(minutes: 3),
      );

  test('does not change mode before enough session evidence', () {
    final session = SessionIntelligenceService();
    final mode = AdaptiveSessionModeService(session: session);

    session.recordPlay(song('one'));
    session.recordSkip('one');

    expect(mode.inferMode(), ListeningMode.balanced);
  });

  test('repeated skips move the temporary session toward discovery', () {
    final session = SessionIntelligenceService();
    final mode = AdaptiveSessionModeService(
      session: session,
      minimumEvents: 3,
    );

    session.recordPlay(song('one'));
    session.recordSkip('one');
    session.recordPlay(song('two'));
    session.recordSkip('two');
    session.recordPlay(song('three'));
    session.recordSkip('three');

    expect(mode.inferMode(), ListeningMode.discovery);
  });

  test('repeated successful plays can move toward favorites', () {
    final session = SessionIntelligenceService();
    final mode = AdaptiveSessionModeService(
      session: session,
      minimumEvents: 3,
    );

    session.recordPlay(song('one', artist: 'Aurora'));
    session.recordPlay(song('two', artist: 'Aurora'));
    session.recordPlay(song('three', artist: 'Aurora'));

    expect(mode.inferMode(), ListeningMode.favorites);
  });

  test('reset returns the temporary mode to balanced', () {
    final session = SessionIntelligenceService();
    final mode = AdaptiveSessionModeService(session: session);

    session.recordPlay(song('one'));
    session.recordSkip('one');
    session.recordPlay(song('two'));
    session.recordSkip('two');
    session.recordPlay(song('three'));
    session.recordSkip('three');

    expect(mode.inferMode(), ListeningMode.discovery);

    mode.reset();
    expect(mode.currentMode, ListeningMode.balanced);
  });

  test('session mode does not mutate persistent taste data', () {
    final session = SessionIntelligenceService();
    final mode = AdaptiveSessionModeService(session: session);

    session.recordPlay(song('one', artist: 'Aurora'));
    session.recordPlay(song('two', artist: 'Aurora'));
    session.recordPlay(song('three', artist: 'Aurora'));

    mode.inferMode();

    expect(session.artistPlayCounts['aurora'], 3);
    expect(mode.currentMode, ListeningMode.favorites);
  });
}
