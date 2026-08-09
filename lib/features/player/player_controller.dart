import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart' as ja;

import '../../data/models/online/online_song.dart';
import '../../data/models/song.dart';
import '../../data/repositories/online_repository.dart';
import '../../core/providers/search_provider.dart';
import 'player_state.dart';

class PlayerController extends StateNotifier<PlayerState> {
  PlayerController({OnlineRepository? onlineRepository})
      : _onlineRepository = onlineRepository,
        super(const PlayerState()) {
    _registerListeners();
  }

  final ja.AudioPlayer _player = ja.AudioPlayer();
  final OnlineRepository? _onlineRepository;

  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<ja.PlayerState>? _playerStateSubscription;
  StreamSubscription<ja.PlayerState>? _processingSubscription;

  void _registerListeners() {
    _positionSubscription = _player.positionStream.listen((position) {
      state = state.copyWith(position: position);
    });

    _durationSubscription = _player.durationStream.listen((duration) {
      state = state.copyWith(
        duration: duration ?? Duration.zero,
      );
    });

    _playerStateSubscription = _player.playerStateStream.listen((playerState) {
      state = state.copyWith(
        isPlaying: playerState.playing,
      );
    });

    _processingSubscription = _player.playerStateStream.listen((playerState) {
      if (playerState.processingState == ja.ProcessingState.completed) {
        nextSong();
      }
    });
  }

  Future<void> playSong(
    Song song, {
    List<Song> queue = const [],
  }) async {
    await _playUri(
      song: song,
      source: _sourceForAudioUrl(song.audioUrl),
      queue: queue,
    );
  }

  /// Plays an online song using a stream URL supplied by the configured
  /// online provider. The provider is responsible for returning a playable
  /// URL that the application is authorized to use.
  Future<void> playOnlineSong(
    OnlineSong song, {
    List<OnlineSong> queue = const [],
  }) async {
    if (_onlineRepository == null) {
      throw StateError('Online repository is not configured.');
    }

    try {
      final resolved = song.streamUrl.trim().isNotEmpty
          ? song.streamUrl.trim()
          : (await _onlineRepository.getStream(song.id)).streamUrl.trim();

      if (resolved.isEmpty) {
        throw StateError('No playable stream was returned for this song.');
      }

      final playableSong = Song(
        id: song.id,
        title: song.title,
        artist: song.artist,
        album: song.album,
        artwork: song.artwork.isEmpty ? null : song.artwork,
        audioUrl: resolved,
        duration: song.duration,
      );

      final localQueue = queue
          .map(
            (item) => Song(
              id: item.id,
              title: item.title,
              artist: item.artist,
              album: item.album,
              artwork: item.artwork.isEmpty ? null : item.artwork,
              audioUrl: item.streamUrl,
              duration: item.duration,
            ),
          )
          .toList();

      await _playUri(
        song: playableSong,
        source: Uri.parse(resolved),
        queue: localQueue.isEmpty ? [playableSong] : localQueue,
      );
    } catch (error, stackTrace) {
      debugPrint('Online playback failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Uri _sourceForAudioUrl(String audioUrl) {
    final value = audioUrl.trim();
    final uri = Uri.tryParse(value);

    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return uri;
    }

    return Uri.file(value);
  }

  Future<void> _playUri({
    required Song song,
    required Uri source,
    required List<Song> queue,
  }) async {
    try {
      await _player.stop();
      await _player.setAudioSource(
        ja.AudioSource.uri(source),
      );
      await _player.play();

      state = state.copyWith(
        currentSong: song,
        queue: queue.isEmpty ? [song] : queue,
        isPlaying: true,
        position: Duration.zero,
        duration: _player.duration ?? song.duration,
      );
    } catch (error, stackTrace) {
      debugPrint('Playback failed');
      debugPrint('Song: ${song.title}');
      debugPrint('Source: $source');
      debugPrint('Error: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else if (_player.audioSource != null) {
      await _player.play();
    }
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> previousSong() async {
    if (state.currentSong == null || state.queue.isEmpty) {
      return;
    }

    final index = state.queue.indexWhere(
      (song) => song.id == state.currentSong!.id,
    );

    if (index > 0) {
      await playSong(
        state.queue[index - 1],
        queue: state.queue,
      );
    }
  }

  Future<void> nextSong() async {
    if (state.currentSong == null || state.queue.isEmpty) {
      return;
    }

    final index = state.queue.indexWhere(
      (song) => song.id == state.currentSong!.id,
    );

    if (index >= 0 && index < state.queue.length - 1) {
      await playSong(
        state.queue[index + 1],
        queue: state.queue,
      );
    } else {
      state = state.copyWith(
        isPlaying: false,
        position: Duration.zero,
      );
    }
  }

  Future<void> toggleShuffle() async {
    final enabled = !state.isShuffleEnabled;

    await _player.setShuffleModeEnabled(enabled);

    state = state.copyWith(
      isShuffleEnabled: enabled,
    );
  }

  Future<void> cycleRepeatMode() async {
    switch (state.repeatMode) {
      case PlayerRepeatMode.off:
        await _player.setLoopMode(ja.LoopMode.all);
        state = state.copyWith(
          repeatMode: PlayerRepeatMode.all,
        );
        break;

      case PlayerRepeatMode.all:
        await _player.setLoopMode(ja.LoopMode.one);
        state = state.copyWith(
          repeatMode: PlayerRepeatMode.one,
        );
        break;

      case PlayerRepeatMode.one:
        await _player.setLoopMode(ja.LoopMode.off);
        state = state.copyWith(
          repeatMode: PlayerRepeatMode.off,
        );
        break;
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _processingSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }
}

final playerControllerProvider =
    StateNotifierProvider<PlayerController, PlayerState>((ref) {
  final repository = ref.watch(onlineRepositoryProvider);
  return PlayerController(onlineRepository: repository);
});
