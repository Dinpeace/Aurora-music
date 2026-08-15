import 'dart:async';

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
  late final Timer _positionTimer;

  bool _loading = true;
  bool _playing = false;
  String? _error;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();

    _youtube = YoutubePlayerService(
      autoPlay: true,
    );

    _positionTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => _updatePosition(),
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
        _playing = false;
        _error = 'This song has no YouTube video ID.';
      });

      return;
    }

    if (mounted) {
      setState(() {
        _loading = true;
        _playing = false;
        _error = null;
        _position = Duration.zero;
        _duration = Duration.zero;
      });
    }

    try {
      debugPrint(
        'Aurora Player: loading $videoId',
      );

      await _youtube.load(videoId);

      final duration = await _youtube.getDuration();

      if (!mounted) return;

      setState(() {
        _loading = false;
        _playing = _youtube.isPlaying;
        _duration = duration;
      });

      debugPrint(
        'Aurora Player: loaded $videoId',
      );
    } catch (error, stackTrace) {
      debugPrint(
        'Aurora Player error: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      if (!mounted) return;

      setState(() {
        _loading = false;
        _playing = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _updatePosition() async {
    if (!mounted || _loading) return;

    try {
      final position =
          await _youtube.getCurrentPosition();

      final duration =
          await _youtube.getDuration();

      if (!mounted) return;

      setState(() {
        _position = position;
        if (duration > Duration.zero) {
          _duration = duration;
        }

        _playing = _youtube.isPlaying;
      });
    } catch (_) {
      // Ignore temporary iframe/player state errors.
    }
  }

  Future<void> _togglePlayPause() async {
    try {
      await _youtube.togglePlayPause();

      if (!mounted) return;

      setState(() {
        _playing = _youtube.isPlaying;
      });
    } catch (error, stackTrace) {
      debugPrint(
        'Aurora Player toggle error: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      _showError(error);
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

      await _updatePosition();
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

      await _updatePosition();
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _seekTo(double value) async {
    try {
      await _youtube.seek(
        Duration(
          milliseconds: value.round(),
        ),
      );

      if (!mounted) return;

      setState(() {
        _position = Duration(
          milliseconds: value.round(),
        );
      });
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

  String _formatDuration(Duration duration) {
    if (duration <= Duration.zero) {
      return '0:00';
    }

    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final song = widget.song;

    final durationMs =
        _duration.inMilliseconds.toDouble();

    final positionMs =
        _position.inMilliseconds
            .clamp(
              0,
              durationMs > 0 ? durationMs : 0,
            )
            .toDouble();

    final hasDuration = durationMs > 0;

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF09090B),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Now Playing',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                24,
                18,
                24,
                36,
              ),
              child: Column(
                children: [
                  _buildArtwork(song),

                  const SizedBox(height: 28),

                  Text(
                    song.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    song.artist,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 16,
                    ),
                  ),

                  if (song.album.trim().isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      song.album,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 13,
                      ),
                    ),
                  ],

                  const SizedBox(height: 34),

                  // -------------------------------------------------------
                  // AURORA PROGRESS BAR
                  // -------------------------------------------------------

                  if (hasDuration)
                    Column(
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            thumbShape:
                                const RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                            ),
                            overlayShape:
                                const RoundSliderOverlayShape(
                              overlayRadius: 16,
                            ),
                            activeTrackColor:
                                const Color(0xFFA855F7),
                            inactiveTrackColor:
                                Colors.white12,
                            thumbColor:
                                const Color(0xFF22D3EE),
                            overlayColor:
                                const Color(0x3322D3EE),
                          ),
                          child: Slider(
                            value: positionMs,
                            min: 0,
                            max: durationMs,
                            onChanged: _loading
                                ? null
                                : _seekTo,
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 4,
                          ),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(_position),
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                _formatDuration(_duration),
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 28),

                  // -------------------------------------------------------
                  // AURORA CONTROLS
                  // -------------------------------------------------------

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed:
                            _loading ? null : _seekBackward,
                        iconSize: 34,
                        color: Colors.white,
                        icon: const Icon(
                          Icons.replay_10_rounded,
                        ),
                      ),

                      const SizedBox(width: 28),

                      Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFFA855F7),
                              Color(0xFF22D3EE),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: IconButton(
                          onPressed:
                              _loading
                                  ? null
                                  : _togglePlayPause,
                          iconSize: 38,
                          color: Colors.white,
                          icon: Icon(
                            _playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                          ),
                        ),
                      ),

                      const SizedBox(width: 28),

                      IconButton(
                        onPressed:
                            _loading ? null : _seekForward,
                        iconSize: 34,
                        color: Colors.white,
                        icon: const Icon(
                          Icons.forward_10_rounded,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  if (_loading)
                    const Column(
                      children: [
                        SizedBox(height: 4),
                        CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Loading song...',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),

                  if (_error != null) ...[
                    const SizedBox(height: 18),
                    _buildPlayerError(_error!),
                  ],

                  const SizedBox(height: 20),

                  OutlinedButton.icon(
                    onPressed:
                        _loading ? null : _loadSong,
                    icon: const Icon(
                      Icons.refresh_rounded,
                    ),
                    label: const Text(
                      'Reload',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(
                        color: Colors.white12,
                      ),
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // -------------------------------------------------------------
            // HIDDEN YOUTUBE PLAYBACK SURFACE
            //
            // The YouTube iframe remains mounted so the existing working
            // playback engine continues to work. Aurora owns the visible UI.
            // -------------------------------------------------------------

            Positioned(
              left: 0,
              top: 0,
              child: IgnorePointer(
                child: SizedBox(
                  width: 1,
                  height: 1,
                  child: YoutubePlayer(
                    controller: _youtube.controller,
                  ),
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

    return Hero(
      tag: 'aurora-artwork-${song.id}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.network(
          artwork,
          width: 300,
          height: 300,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
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
      ),
    );
  }

  Widget _artworkPlaceholder() {
    return Container(
      width: 300,
      height: 300,
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
        size: 86,
      ),
    );
  }

  Widget _buildPlayerError(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF3B1010),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.redAccent.withValues(
            alpha: 0.35,
          ),
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
    _positionTimer.cancel();
    _youtube.dispose();
    super.dispose();
  }
}