class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String artwork;
  final String audioUrl;
  final Duration duration;
  final bool favorite;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.artwork,
    required this.audioUrl,
    required this.duration,
    this.favorite = false,
  });

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? artwork,
    String? audioUrl,
    Duration? duration,
    bool? favorite,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      artwork: artwork ?? this.artwork,
      audioUrl: audioUrl ?? this.audioUrl,
      duration: duration ?? this.duration,
      favorite: favorite ?? this.favorite,
    );
  }
}