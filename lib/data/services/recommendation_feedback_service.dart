import '../models/listening_history_entry.dart';

/// Converts playback behavior into a bounded recommendation feedback score.
class RecommendationFeedbackService {
  const RecommendationFeedbackService({
    this.playWeight = 0.35,
    this.completionWeight = 1.25,
    this.replayWeight = 0.45,
    this.skipWeight = 2.5,
    this.maxPositive = 5.0,
    this.maxNegative = -8.0,
  });

  final double playWeight;
  final double completionWeight;
  final double replayWeight;
  final double skipWeight;
  final double maxPositive;
  final double maxNegative;

  double score(ListeningHistoryEntry? entry) {
    if (entry == null) return 0.0;

    final plays = entry.playCount.clamp(0, 50).toDouble();
    final skips = entry.skipCount.clamp(0, 20).toDouble();

    var completion = 0.0;
    if (entry.duration > Duration.zero) {
      final position =
          entry.position < Duration.zero ? Duration.zero : entry.position;
      final ratio =
          (position.inMilliseconds / entry.duration.inMilliseconds)
              .clamp(0.0, 1.0);
      completion = ratio * completionWeight;
    }

    final replayCount = (plays - 1).clamp(0, 10).toDouble();
    final replay = replayCount * replayWeight;

    final value = (plays * playWeight) +
        completion +
        replay -
        (skips * skipWeight);

    return value.clamp(maxNegative, maxPositive).toDouble();
  }

  bool shouldSuppress(ListeningHistoryEntry? entry) {
    if (entry == null) return false;
    return entry.skipCount >= 3 && entry.playCount <= entry.skipCount;
  }
}
