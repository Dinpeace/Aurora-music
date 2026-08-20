/// Flutter-side normalized catalog identity used by the online catalog.
///
/// The server remains authoritative for deduplication. This class is useful
/// for stable client-side display and cache keys.
class AuroraCatalogIdentityService {
  String identity({
    required String title,
    required String artist,
    required String album,
  }) {
    final normalizedTitle = _normalize(title);
    final normalizedArtist = _normalize(artist);
    final normalizedAlbum = _normalize(album);

    return '${_compact(normalizedTitle)}|'
        '${_compact(normalizedArtist)}|'
        '${_compact(normalizedAlbum)}';
  }

  String _normalize(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\([^)]*\)'), ' ')
      .replaceAll(RegExp(r'\[[^\]]*\]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  String _compact(String value) =>
      value.replaceAll(RegExp(r'[^a-z0-9]+'), '');
}
