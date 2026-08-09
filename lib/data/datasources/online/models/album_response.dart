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

  factory AlbumResponse.fromJson(Map<String, dynamic> json) {
    return AlbumResponse(
      id: json['id']?.toString() ?? '',
      title: _text(json['title'] ?? json['name'], 'Unknown Album'),
      artist: _text(json['artist'], 'Unknown Artist'),
      artwork: _text(json['artwork'] ?? json['thumbnail']),
    );
  }

  static String _text(dynamic value, [String fallback = '']) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }
}
