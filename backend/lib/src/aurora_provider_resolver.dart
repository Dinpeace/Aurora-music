/// Provider-normalization and source-resolution layer for Aurora Cloud Catalog.
///
/// This layer is intentionally provider-agnostic. It does not fetch or extract
/// media. It only resolves normalized catalog metadata into an ordered list of
/// provider sources that a separately authorized playback layer can consume.
class AuroraProviderResolver {
  AuroraProviderResolver({
    Iterable<AuroraProviderSource> sources = const [],
    this.providerPriority = const ['aurora', 'youtube', 'licensed'],
  }) : _sources = List.unmodifiable(sources);

  final List<AuroraProviderSource> _sources;
  final List<String> providerPriority;

  AuroraResolvedTrack? resolve(String auroraId) {
    final id = auroraId.trim();
    if (id.isEmpty) return null;

    final matches = _sources.where((source) => source.auroraId == id).toList();

    if (matches.isEmpty) return null;

    matches.sort((a, b) {
      final aRank = _rank(a.provider);
      final bRank = _rank(b.provider);
      final rank = aRank.compareTo(bRank);
      if (rank != 0) return rank;

      final availability = (b.available ? 1 : 0).compareTo(
        a.available ? 1 : 0,
      );
      if (availability != 0) return availability;

      return b.qualityScore.compareTo(a.qualityScore);
    });

    return AuroraResolvedTrack(
      auroraId: id,
      sources: List.unmodifiable(matches),
      selected: matches.firstWhere(
        (source) => source.available,
        orElse: () => matches.first,
      ),
    );
  }

  List<AuroraProviderSource> sourcesFor(String auroraId) =>
      _sources.where((source) => source.auroraId == auroraId.trim()).toList(
            growable: false,
          );

  int _rank(String provider) {
    final index = providerPriority.indexOf(provider);
    return index < 0 ? providerPriority.length : index;
  }
}

class AuroraProviderSource {
  const AuroraProviderSource({
    required this.auroraId,
    required this.provider,
    required this.providerId,
    required this.available,
    required this.qualityScore,
    required this.title,
    required this.artist,
    required this.album,
    this.artworkUrl,
    this.playbackReference,
  });

  final String auroraId;
  final String provider;
  final String providerId;
  final bool available;
  final double qualityScore;
  final String title;
  final String artist;
  final String album;
  final String? artworkUrl;

  /// Opaque reference for a separately authorized playback layer.
  final String? playbackReference;

  Map<String, dynamic> toJson() => {
        'auroraId': auroraId,
        'provider': provider,
        'providerId': providerId,
        'available': available,
        'qualityScore': qualityScore,
        'title': title,
        'artist': artist,
        'album': album,
        'artworkUrl': artworkUrl,
        'playbackReference': playbackReference,
      };

  factory AuroraProviderSource.fromJson(Map value) => AuroraProviderSource(
        auroraId: '${value['auroraId'] ?? ''}'.trim(),
        provider: '${value['provider'] ?? ''}'.trim(),
        providerId: '${value['providerId'] ?? ''}'.trim(),
        available: value['available'] == true,
        qualityScore: _double(value['qualityScore']),
        title: '${value['title'] ?? ''}'.trim(),
        artist: '${value['artist'] ?? ''}'.trim(),
        album: '${value['album'] ?? ''}'.trim(),
        artworkUrl: _nullable(value['artworkUrl']),
        playbackReference: _nullable(value['playbackReference']),
      );
}

class AuroraResolvedTrack {
  const AuroraResolvedTrack({
    required this.auroraId,
    required this.sources,
    required this.selected,
  });

  final String auroraId;
  final List<AuroraProviderSource> sources;
  final AuroraProviderSource selected;

  bool get hasAvailableSource => sources.any((source) => source.available);
}

double _double(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

String? _nullable(dynamic value) =>
    value is String && value.trim().isNotEmpty ? value.trim() : null;
