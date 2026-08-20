/// Cloud Catalog v3: deterministic metadata normalization and matching.
///
/// This service does not delete or mutate provider data. It produces a
/// normalized key and match candidates so a production catalog can decide
/// whether provider records represent the same Aurora track.
class AuroraCatalogMatcher {
  AuroraCatalogMatcher({
    this.titleWeight = 0.45,
    this.artistWeight = 0.30,
    this.albumWeight = 0.15,
    this.durationWeight = 0.10,
  });

  final double titleWeight;
  final double artistWeight;
  final double albumWeight;
  final double durationWeight;

  AuroraNormalizedMetadata normalize(AuroraRawMetadata raw) {
    final title = _clean(raw.title);
    final artist = _clean(raw.artist);
    final album = _clean(raw.album);

    return AuroraNormalizedMetadata(
      title: title,
      artist: artist,
      album: album,
      key: _key(title, artist, album),
      durationMs: raw.durationMs < 0 ? 0 : raw.durationMs,
    );
  }

  double similarity(
    AuroraNormalizedMetadata a,
    AuroraNormalizedMetadata b,
  ) {
    final title = _textSimilarity(a.title, b.title);
    final artist = _textSimilarity(a.artist, b.artist);
    final album = _textSimilarity(a.album, b.album);
    final duration = _durationSimilarity(a.durationMs, b.durationMs);

    final weightTotal =
        titleWeight + artistWeight + albumWeight + durationWeight;

    if (weightTotal <= 0) return 0;

    return _clamp01(
      (title * titleWeight +
              artist * artistWeight +
              album * albumWeight +
              duration * durationWeight) /
          weightTotal,
    );
  }

  AuroraMatchDecision match(
    AuroraNormalizedMetadata a,
    AuroraNormalizedMetadata b, {
    double threshold = 0.82,
  }) {
    final score = similarity(a, b);

    return AuroraMatchDecision(
      matched: score >= threshold,
      score: score,
      exactKeyMatch: a.key == b.key,
    );
  }

  String _key(String title, String artist, String album) =>
      '${_compact(title)}|${_compact(artist)}|${_compact(album)}';

  String _clean(String value) {
    final lower = value.trim().toLowerCase();
    return lower
        .replaceAll(RegExp(r'\([^)]*\)'), ' ')
        .replaceAll(RegExp(r'\[[^\]]*\]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _compact(String value) =>
      value.replaceAll(RegExp(r'[^a-z0-9]+'), '');

  double _textSimilarity(String a, String b) {
    if (a.isEmpty || b.isEmpty) return a == b ? 1 : 0;
    if (a == b) return 1;

    final aa = _compact(a);
    final bb = _compact(b);

    if (aa == bb) return 1;
    if (aa.contains(bb) || bb.contains(aa)) return .85;

    final distance = _levenshtein(aa, bb);
    final maxLength = aa.length > bb.length ? aa.length : bb.length;

    return _clamp01(1 - distance / maxLength);
  }

  double _durationSimilarity(int a, int b) {
    if (a <= 0 || b <= 0) return .5;
    final difference = (a - b).abs();

    if (difference <= 2000) return 1;
    if (difference >= 15000) return 0;

    return 1 - (difference - 2000) / 13000;
  }

  int _levenshtein(String a, String b) {
    final previous = List<int>.generate(b.length + 1, (i) => i);

    for (var i = 0; i < a.length; i++) {
      final current = List<int>.filled(b.length + 1, 0);
      current[0] = i + 1;

      for (var j = 0; j < b.length; j++) {
        final insertion = current[j] + 1;
        final deletion = previous[j + 1] + 1;
        final substitution =
            previous[j] + (a[i] == b[j] ? 0 : 1);

        current[j + 1] =
            [insertion, deletion, substitution].reduce(_min);
      }

      for (var j = 0; j < previous.length; j++) {
        previous[j] = current[j];
      }
    }

    return previous[b.length];
  }

  int _min(int a, int b) => a < b ? a : b;

  double _clamp01(double value) => value.clamp(0.0, 1.0).toDouble();
}

class AuroraRawMetadata {
  const AuroraRawMetadata({
    required this.title,
    required this.artist,
    required this.album,
    required this.durationMs,
  });

  final String title;
  final String artist;
  final String album;
  final int durationMs;
}

class AuroraNormalizedMetadata {
  const AuroraNormalizedMetadata({
    required this.title,
    required this.artist,
    required this.album,
    required this.key,
    required this.durationMs,
  });

  final String title;
  final String artist;
  final String album;
  final String key;
  final int durationMs;
}

class AuroraMatchDecision {
  const AuroraMatchDecision({
    required this.matched,
    required this.score,
    required this.exactKeyMatch,
  });

  final bool matched;
  final double score;
  final bool exactKeyMatch;
}
