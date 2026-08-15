import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../core/youtube/youtube_player_service.dart';
import '../../data/models/online/online_song.dart';

class YoutubeTestScreen extends StatefulWidget {
  const YoutubeTestScreen({
    super.key,
    required this.song,
  });

  final OnlineSong song;

  @override
  State<YoutubeTestScreen> createState() =>
      _YoutubeTestScreenState();
}

class _YoutubeTestScreenState
    extends State<YoutubeTestScreen> {
  late final YoutubePlayerService _youtube;

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();

    _youtube = YoutubePlayerService(
      autoPlay: true,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSong();
    });
  }

  Future<void> _loadSong() async {
    final videoId = widget.song.id.trim();

    if (videoId.isEmpty) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'This song has no YouTube video ID.';
      });

      return;
    }

    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      debugPrint(
        'Aurora Test Player: loading $videoId',
      );

      await _youtube.load(videoId);

      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      debugPrint(
        'Aurora Test Player: loaded $videoId',
      );
    } catch (error, stackTrace) {
      debugPrint(
        'Aurora Test Player error: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _togglePlayPause() async {
    try {
      await _youtube.togglePlayPause();
    } catch (error, stackTrace) {
      debugPrint(
        'Aurora Test Player toggle error: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      if (!mounted) return;

      setState(() {
        _error = error.toString();
      });
    }
  }

  Future<void> _seekBackward() async {
    try {
      final position =
          await _youtube.getCurrentPosition();

      final target =
          position - const Duration(seconds: 10);

      await _youtube.seek(
        target.isNegative
            ? Duration.zero
            : target,
      );
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _seekForward() async {
    try {
      final position =
          await _youtube.getCurrentPosition();

      final duration =
          await _youtube.getDuration();

      final target =
          position + const Duration(seconds: 10);

      await _youtube.seek(
        target > duration
            ? duration
            : target,
      );
    } catch (error) {
      _showError(error);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;

    setState(() {
      _error = error.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final song = widget.song;

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF09090B),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Now Playing',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),

            // ---------------------------------------------------------------
            // YOUTUBE PLAYER
            // ---------------------------------------------------------------

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(18),
                child: YoutubePlayer(
                  controller: _youtube.controller,
                  aspectRatio: 16 / 9,
                  autoFullScreen: true,
                  keepAlive: true,
                ),
              ),
            ),

            const SizedBox(height: 24),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  0,
                  20,
                  32,
                ),
                child: Column(
                  children: [
                    // -------------------------------------------------------
                    // ARTWORK
                    // -------------------------------------------------------

                    _buildArtwork(song),

                    const SizedBox(height: 22),

                    // -------------------------------------------------------
                    // TITLE
                    // -------------------------------------------------------

                    Text(
                      song.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 7),

                    // -------------------------------------------------------
                    // ARTIST
                    // -------------------------------------------------------

                    Text(
                      song.artist,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 15,
                      ),
                    ),

                    if (song.album
                        .trim()
                        .isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        song.album,
                        textAlign:
                            TextAlign.center,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 13,
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // -------------------------------------------------------
                    // PLAYER STATE
                    // -------------------------------------------------------

                    YoutubeValueBuilder(
                      controller: _youtube.controller,
                      builder: (
                        context,
                        value,
                      ) {
                        final isPlaying =
                            value.playerState ==
                                PlayerState.playing;

                        final isBuffering =
                            value.playerState ==
                                PlayerState.buffering;

                        final hasError =
                            value.hasError;

                        if (hasError) {
                          return _buildPlayerError(
                            value.error.toString(),
                          );
                        }

                        return Column(
                          children: [
                            if (_loading ||
                                isBuffering)
                              const Padding(
                                padding:
                                    EdgeInsets.only(
                                  bottom: 16,
                                ),
                                child:
                                    CircularProgressIndicator(
                                  color:
                                      Colors.white,
                                ),
                              ),

                            if (_error != null)
                              _buildPlayerError(
                                _error!,
                              ),

                            const SizedBox(
                              height: 8,
                            ),

                            // -------------------------------------------------
                            // CUSTOM CONTROLS
                            // -------------------------------------------------

                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .center,
                              children: [
                                IconButton(
                                  onPressed:
                                      _loading
                                          ? null
                                          : _seekBackward,
                                  iconSize: 34,
                                  color: Colors.white,
                                  icon: const Icon(
                                    Icons
                                        .replay_10_rounded,
                                  ),
                                ),

                                const SizedBox(
                                  width: 22,
                                ),

                                Container(
                                  width: 68,
                                  height: 68,
                                  decoration:
                                      const BoxDecoration(
                                    shape:
                                        BoxShape.circle,
                                    gradient:
                                        LinearGradient(
                                      colors: [
                                        Color(
                                          0xFFA855F7,
                                        ),
                                        Color(
                                          0xFF22D3EE,
                                        ),
                                      ],
                                    ),
                                  ),
                                  child:
                                      IconButton(
                                    onPressed:
                                        _loading
                                            ? null
                                            : _togglePlayPause,
                                    iconSize: 36,
                                    color:
                                        Colors.white,
                                    icon: Icon(
                                      isPlaying
                                          ? Icons
                                              .pause_rounded
                                          : Icons
                                              .play_arrow_rounded,
                                    ),
                                  ),
                                ),

                                const SizedBox(
                                  width: 22,
                                ),

                                IconButton(
                                  onPressed:
                                      _loading
                                          ? null
                                          : _seekForward,
                                  iconSize: 34,
                                  color: Colors.white,
                                  icon: const Icon(
                                    Icons
                                        .forward_10_rounded,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // -------------------------------------------------------
                    // RELOAD
                    // -------------------------------------------------------

                    OutlinedButton.icon(
                      onPressed:
                          _loading
                              ? null
                              : _loadSong,
                      icon: const Icon(
                        Icons.refresh_rounded,
                      ),
                      label: const Text(
                        'Reload video',
                      ),
                      style:
                          OutlinedButton.styleFrom(
                        foregroundColor:
                            Colors.white,
                        side: const BorderSide(
                          color: Colors.white24,
                        ),
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtwork(OnlineSong song) {
    final artwork = song.artwork.trim();

    if (artwork.isEmpty) {
      return _artworkPlaceholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Image.network(
        artwork,
        width: 220,
        height: 220,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        errorBuilder: (
          context,
          error,
          stackTrace,
        ) {
          return _artworkPlaceholder();
        },
        loadingBuilder: (
          context,
          child,
          loadingProgress,
        ) {
          if (loadingProgress == null) {
            return child;
          }

          return _artworkPlaceholder();
        },
      ),
    );
  }

  Widget _artworkPlaceholder() {
    return Container(
      width: 220,
      height: 220,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFA855F7),
            Color(0xFF22D3EE),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(
        Icons.music_note_rounded,
        color: Colors.white,
        size: 76,
      ),
    );
  }

  Widget _buildPlayerError(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF3B1010),
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: Colors.redAccent
              .withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.redAccent,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _youtube.dispose();
    super.dispose();
  }
}