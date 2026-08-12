import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../core/youtube/youtube_player_service.dart';
import '../../data/models/online/online_song.dart';

class YoutubeTestScreen extends StatefulWidget {
  const YoutubeTestScreen({
    super.key,
    this.song,
  });

  final OnlineSong? song;

  @override
  State<YoutubeTestScreen> createState() => _YoutubeTestScreenState();
}

class _YoutubeTestScreenState extends State<YoutubeTestScreen> {
  late final YoutubePlayerService _youtube;
  late final TextEditingController _videoIdController;

  String _status = 'Ready';

  @override
  void initState() {
    super.initState();

    _youtube = YoutubePlayerService(
      autoPlay: true,
    );

    _videoIdController = TextEditingController(
      text: widget.song?.id ?? '',
    );

    if (widget.song != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadVideo();
      });
    }
  }

  Future<void> _loadVideo() async {
    final videoId = _videoIdController.text.trim();

    if (videoId.isEmpty) {
      setState(() {
        _status = 'No YouTube video ID.';
      });
      return;
    }

    try {
      setState(() {
        _status = 'Loading...';
      });

      await _youtube.load(videoId);

      if (!mounted) {
        return;
      }

      setState(() {
        _status = 'Playing';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _status = 'Playback error: $error';
      });
    }
  }

  Future<void> _play() async {
    try {
      await _youtube.play();

      if (!mounted) {
        return;
      }

      setState(() {
        _status = 'Playing';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _status = 'Playback error: $error';
      });
    }
  }

  Future<void> _pause() async {
    try {
      await _youtube.pause();

      if (!mounted) {
        return;
      }

      setState(() {
        _status = 'Paused';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _status = 'Playback error: $error';
      });
    }
  }

  Future<void> _seek() async {
    try {
      await _youtube.seek(
        const Duration(seconds: 30),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _status = 'Seeked to 30 seconds';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _status = 'Seek error: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final song = widget.song;

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        title: Text(
          song?.title ?? 'YouTube Player Test',
        ),
        backgroundColor: const Color(0xFF09090B),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: YoutubePlayer(
                controller: _youtube.controller,
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    if (song != null) ...[
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(12),
                            child: song.artwork.isNotEmpty
                                ? Image.network(
                                    song.artwork,
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (
                                      context,
                                      error,
                                      stackTrace,
                                    ) {
                                      return _artworkPlaceholder();
                                    },
                                  )
                                : _artworkPlaceholder(),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  song.title,
                                  maxLines: 2,
                                  overflow:
                                      TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  song.artist,
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white60,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],

                    const Text(
                      'YouTube Video ID',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    TextField(
                      controller: _videoIdController,
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                      decoration: InputDecoration(
                        hintText: 'YouTube video ID',
                        hintStyle: const TextStyle(
                          color: Colors.white38,
                        ),
                        filled: true,
                        fillColor: Colors.white10,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                      ),
                      onSubmitted: (_) => _loadVideo(),
                    ),

                    const SizedBox(height: 16),

                    FilledButton(
                      onPressed: _loadVideo,
                      child: const Text('LOAD & PLAY'),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      _status,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _play,
                            child: const Text('PLAY'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _pause,
                            child: const Text('PAUSE'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    OutlinedButton(
                      onPressed: _seek,
                      child: const Text(
                        'SEEK TO 30 SECONDS',
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

  Widget _artworkPlaceholder() {
    return Container(
      width: 64,
      height: 64,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFA855F7),
            Color(0xFF22D3EE),
          ],
        ),
      ),
      child: const Icon(
        Icons.music_note_rounded,
        color: Colors.white,
      ),
    );
  }

  @override
  void dispose() {
    _videoIdController.dispose();
    _youtube.dispose();
    super.dispose();
  }
}