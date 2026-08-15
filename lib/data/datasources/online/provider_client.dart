import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import 'package:aurora_music/data/models/online/online_song.dart';
import 'models/album_response.dart';
import 'models/artist_response.dart';
import 'models/search_response.dart';
import 'models/stream_response.dart';
import 'music_provider.dart';

class ProviderClient implements MusicProvider {
  ProviderClient();

  final YoutubeExplode _youtube = YoutubeExplode();

  bool _disposed = false;

  @override
  Future<SearchResponse> search(String query) async {
    _checkDisposed();

    final normalizedQuery = query.trim();

    if (normalizedQuery.isEmpty) {
      return SearchResponse.empty();
    }

    try {
      final results = await _youtube.search.search(normalizedQuery);

      final songs = results
          .whereType<Video>()
          .map(
            (video) => OnlineSong(
              id: video.id.value,
              title: _text(video.title, fallback: 'Unknown Title'),
              artist: _text(video.author, fallback: 'YouTube'),
              album: 'YouTube',
              artwork: _thumbnail(video),
              streamUrl: '',
              duration: video.duration ?? Duration.zero,
            ),
          )
          .toList();

      return SearchResponse(songs: songs);
    } catch (error) {
      throw Exception('YouTube search failed: $error');
    }
  }

  @override
  Future<List<OnlineSong>> getTrending() async {
    _checkDisposed();

    try {
      final results = await _youtube.search.search('popular music');

      return results
          .whereType<Video>()
          .map(
            (video) => OnlineSong(
              id: video.id.value,
              title: _text(video.title, fallback: 'Unknown Title'),
              artist: _text(video.author, fallback: 'YouTube'),
              album: 'YouTube',
              artwork: _thumbnail(video),
              streamUrl: '',
              duration: video.duration ?? Duration.zero,
            ),
          )
          .toList();
    } catch (error) {
      throw Exception('YouTube trending failed: $error');
    }
  }

  @override
  Future<List<AlbumResponse>> getAlbums() async {
    _checkDisposed();

    // YouTube provider does not currently expose
    // Aurora's album endpoint.
    return const [];
  }

  @override
  Future<List<ArtistResponse>> getArtists() async {
    _checkDisposed();

    // YouTube provider does not currently expose
    // Aurora's artist endpoint.
    return const [];
  }

  @override
  Future<StreamResponse> getStream(String songId) async {
    _checkDisposed();

    final videoId = songId.trim();

    if (videoId.isEmpty) {
      throw ArgumentError.value(
        songId,
        'songId',
        'YouTube video ID cannot be empty.',
      );
    }

    try {
      final manifest = await _youtube.videos.streams.getManifest(videoId);

      if (manifest.audioOnly.isEmpty) {
        throw StateError('YouTube did not provide an audio stream.');
      }

      // A 128 kbps-or-lower stream starts substantially faster on mobile
      // connections while remaining transparent for typical music playback.
      // Fall back to the best available stream when YouTube offers no such
      // rendition.
      final mobileStreams = manifest.audioOnly
          .where((stream) => stream.bitrate.bitsPerSecond <= 128000)
          .toList();
      final audioStream = mobileStreams.isEmpty
          ? manifest.audioOnly.withHighestBitrate()
          : mobileStreams.withHighestBitrate();

      return StreamResponse(
        streamUrl: audioStream.url.toString(),
        lyricsUrl: null,
      );
    } catch (error) {
      throw Exception('YouTube audio stream failed: $error');
    }
  }

  String _thumbnail(Video video) {
    try {
      return video.thumbnails.maxResUrl;
    } catch (_) {
      try {
        return video.thumbnails.highResUrl;
      } catch (_) {
        return '';
      }
    }
  }

  String _text(String value, {String fallback = ''}) {
    final text = value.trim();

    if (text.isEmpty) {
      return fallback;
    }

    return text;
  }

  void _checkDisposed() {
    if (_disposed) {
      throw StateError('ProviderClient has already been disposed.');
    }
  }

  void dispose() {
    if (_disposed) {
      return;
    }

    _disposed = true;
    _youtube.close();
  }
}
