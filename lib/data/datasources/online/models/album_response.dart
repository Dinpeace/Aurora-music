class AlbumResponse {
  final String id;
  final String title;
  final String artist;
  final String artwork;

  const AlbumResponse({
    required this.id,
    required this.title,
    required this.artist,
    required this.artwork,
  });

  factory AlbumResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return AlbumResponse(
      id: _text(json['id']),
      title: _text(
        json['title'] ?? json['name'],
        fallback: 'Unknown Album',
      ),
      artist: _text(
        json['artist'] ?? json['artistName'],
        fallback: 'Unknown Artist',
      ),
      artwork: _text(
        json['artwork'] ??
            json['thumbnail'] ??
            json['thumbnailUrl'],
      ),
    );
  }

  static String _text(
    dynamic value, {
    String fallback = '',
  }) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }
}