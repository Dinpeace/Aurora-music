class ArtistResponse {
  final String id;
  final String name;
  final String artwork;

  const ArtistResponse({
    required this.id,
    required this.name,
    required this.artwork,
  });

  factory ArtistResponse.fromJson(Map<String, dynamic> json) {
    return ArtistResponse(
      id: json['id']?.toString() ?? '',
      name: _text(json['name'] ?? json['artist'], 'Unknown Artist'),
      artwork: _text(json['artwork'] ?? json['thumbnail']),
    );
  }

  static String _text(dynamic value, [String fallback = '']) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }
}
