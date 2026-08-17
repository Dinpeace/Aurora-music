import 'package:flutter_test/flutter_test.dart';

import 'package:aurora_music/data/models/listening_history_entry.dart';
import 'package:aurora_music/data/models/song.dart';
import 'package:aurora_music/data/services/recommendation_feedback_service.dart';

void main() {
  const service = RecommendationFeedbackService();

  Song song() {
    return Song(
      id: 'one',
      title: 'One',
      artist: 'Aurora',
      album: 'Album',
      audioUrl: '/music/one.mp3',
      duration: const Duration(minutes: 3),
    );
  }

  ListeningHistoryEntry entry({
    int plays = 1,
    int skips = 0,
    Duration position = const Duration(minutes: 3),
  }) {
    return ListeningHistoryEntry(
      song: song(),
      lastPlayed: DateTime(2026, 1, 1),
      playCount: plays,
      position: position,
      duration: song().duration,
      skipCount: skips,
    );
  }

  test('no history has neutral feedback', () {
    expect(service.score(null), 0);
    expect(service.shouldSuppress(null), isFalse);
  });

  test('completed replay receives positive feedback', () {
    final first = service.score(entry(plays: 1));
    final replay = service.score(entry(plays: 4));
    expect(first, greaterThan(0));
    expect(replay, greaterThan(first));
  });

  test('skips reduce feedback strongly', () {
    final liked = service.score(entry(plays: 2));
    final skipped = service.score(entry(plays: 2, skips: 3));
    expect(skipped, lessThan(liked));
  });

  test('repeated low-value skips can suppress a track', () {
    expect(service.shouldSuppress(entry(plays: 2, skips: 3)), isTrue);
    expect(service.shouldSuppress(entry(plays: 10, skips: 3)), isFalse);
  });

  test('feedback is bounded', () {
    final score = service.score(entry(plays: 50));
    final negative = service.score(entry(plays: 1, skips: 20));
    expect(score, lessThanOrEqualTo(5));
    expect(negative, greaterThanOrEqualTo(-8));
  });
}
