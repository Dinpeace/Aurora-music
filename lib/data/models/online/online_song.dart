class OnlineSong {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String artwork;
  final String streamUrl;
  final Duration duration;

  const OnlineSong({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.artwork,
    required this.streamUrl,
    required this.duration,
  });

  factory OnlineSong.fromJson(Map<String, dynamic> json) {
    return OnlineSong(
      id: _text(json['id'] ?? json['videoId'] ?? json['video_id']),
      title: _text(
        json['title'] ?? json['name'],
        fallback: 'Unknown Title',
      ),
      artist: _text(
        json['artist'] ?? json['artistName'],
        fallback: 'Unknown Artist',
      ),
      album: _text(
        json['album'] ?? json['albumName'],
        fallback: 'Unknown Album',
      ),
      artwork: _text(
        json['artwork'] ?? json['thumbnail'] ?? json['thumbnailUrl'],
      ),
      streamUrl: _text(
        json['streamUrl'] ?? json['stream_url'] ?? json['url'],
      ),
      duration: _duration(json['duration']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'artwork': artwork,
      'streamUrl': streamUrl,
      'duration': duration.inMilliseconds,
    };
  }

  static String _text(
    dynamic value, {
    String fallback = '',
  }) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static Duration _duration(dynamic value) {
    if (value is Duration) return value;

    if (value is num) {
      final number = value.toInt();
      return Duration(
        milliseconds: number < 100000 ? number * 1000 : number,
      );
    }

    if (value is String) {
      final text = value.trim();
      final parts = text.split(':');

      if (parts.length == 2) {
        return Duration(
          minutes: int.tryParse(parts[0]) ?? 0,
          seconds: int.tryParse(parts[1]) ?? 0,
        );
      }

      if (parts.length == 3) {
        return Duration(
          hours: int.tryParse(parts[0]) ?? 0,
          minutes: int.tryParse(parts[1]) ?? 0,
          seconds: int.tryParse(parts[2]) ?? 0,
        );
      }
    }

    return Duration.zero;
  }
}
