import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:youtube_player_iframe/youtube_player_iframe.dart' as yt;

import '../../core/youtube/youtube_player_service.dart';
import '../../data/models/online/online_song.dart';
import '../../data/models/song.dart';
import 'player_state.dart';

enum _PlaybackEngine { none, justAudio, youtube }

class PlayerController extends StateNotifier<PlayerState> {
  PlayerController() : super(const PlayerState()) {
    _initialize();
  }

  late ja.AndroidEqualizer _equalizer;
  late ja.AudioPlayer _player;
  late YoutubePlayerService _youtube;

  ja.AudioPlayer? _transitionPlayer;
  ja.AndroidEqualizer? _transitionEqualizer;

  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<ja.PlayerState>? _playerStateSubscription;
  StreamSubscription<yt.YoutubePlayerValue>? _youtubeValueSubscription;
  Timer? _youtubePositionTimer;
  Timer? _sleepTimer;
  Timer? _crossfadeTimer;

  List<double> _equalizerLevels = List<double>.filled(5, 0.0);

  bool _crossfadeInProgress = false;
  Song? _crossfadeTarget;

  _PlaybackEngine _engine = _PlaybackEngine.none;
  bool _isOnlineQueue = false;

  yt.YoutubePlayerController get youtubeController => _youtube.controller;
  bool get usesYoutubePlayer => _engine == _PlaybackEngine.youtube;

  // ===========================================================================
  // INITIALIZATION
  // ===========================================================================

  void _initialize() {
    _equalizer = ja.AndroidEqualizer();

    _player = ja.AudioPlayer(
      audioPipeline: ja.AudioPipeline(androidAudioEffects: [_equalizer]),
    );

    _youtube = YoutubePlayerService(autoPlay: true);

    _bindJustAudioListeners();
    _bindYoutubeListeners();
  }

  void _bindYoutubeListeners() {
    _youtubeValueSubscription = _youtube.valueStream.listen((value) {
      if (_engine != _PlaybackEngine.youtube) {
        return;
      }

      final playerState = value.playerState;
      final isPlaying = playerState == yt.PlayerState.playing;
      final isBuffering = playerState == yt.PlayerState.buffering;

      state = state.copyWith(isPlaying: isPlaying, isBuffering: isBuffering);

      if (playerState == yt.PlayerState.ended) {
        nextSong();
      }
    });
  }

  void _startYoutubePositionUpdates() {
    _youtubePositionTimer?.cancel();
    _youtubePositionTimer = Timer.periodic(const Duration(milliseconds: 500), (
      _,
    ) async {
      if (_engine != _PlaybackEngine.youtube) {
        return;
      }

      try {
        final position = await _youtube.getCurrentPosition();
        final duration = await _youtube.getDuration();

        if (_engine != _PlaybackEngine.youtube) {
          return;
        }

        state = state.copyWith(position: position, duration: duration);
      } catch (_) {
        // The embedded player may reject queries while it starts playback.
      }
    });
  }

  void _stopYoutubePositionUpdates() {
    _youtubePositionTimer?.cancel();
    _youtubePositionTimer = null;
  }

  // ===========================================================================
  // JUST AUDIO LISTENERS
  // ===========================================================================

  void _bindJustAudioListeners() {
    _positionSubscription = _player.positionStream.listen((position) {
      if (_engine != _PlaybackEngine.justAudio) {
        return;
      }

      state = state.copyWith(position: position);

      _maybeStartCrossfade();
    });

    _durationSubscription = _player.durationStream.listen((duration) {
      if (_engine != _PlaybackEngine.justAudio) {
        return;
      }

      state = state.copyWith(duration: duration ?? Duration.zero);
    });

    _playerStateSubscription = _player.playerStateStream.listen((playerState) {
      if (_engine != _PlaybackEngine.justAudio) {
        return;
      }

      state = state.copyWith(
        isPlaying: playerState.playing,
        isBuffering:
            playerState.processingState == ja.ProcessingState.loading ||
            playerState.processingState == ja.ProcessingState.buffering,
      );
    });

    _player.playerStateStream.listen((playerState) {
      if (_engine != _PlaybackEngine.justAudio) {
        return;
      }

      if (playerState.processingState == ja.ProcessingState.completed &&
          !_crossfadeInProgress) {
        nextSong();
      }
    });
  }

  // ===========================================================================
  // LOCAL PLAYBACK
  // ===========================================================================

  Future<void> playSong(Song song, {List<Song> queue = const []}) async {
    _isOnlineQueue = false;
    await _playUri(
      song: song,
      source: _sourceForAudioUrl(song.audioUrl),
      queue: queue,
    );
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
      await _stopCurrentPlayback();

      _engine = _PlaybackEngine.justAudio;

      await _player.stop();

      await _player.setVolume(1.0);

      await _player.setAudioSource(ja.AudioSource.uri(source));

      await _player.play();

      state = state.copyWith(
        currentSong: song,
        queue: queue.isEmpty ? [song] : queue,
        isPlaying: true,
        isBuffering: false,
        position: Duration.zero,
        duration: _player.duration ?? song.duration,
      );

      await setEqualizerLevels(_equalizerLevels);
    } catch (error, stackTrace) {
      debugPrint('Audio playback failed: $error');

      debugPrintStack(stackTrace: stackTrace);

      _engine = _PlaybackEngine.none;

      state = state.copyWith(isPlaying: false, isBuffering: false);

      rethrow;
    }
  }

  // ===========================================================================
  // ONLINE PLAYBACK
  // ===========================================================================

  Future<void> playOnlineSong(
    OnlineSong song, {
    List<OnlineSong> queue = const [],
  }) async {
    final videoId = song.id.trim();

    if (videoId.isEmpty) {
      throw ArgumentError.value(
        song.id,
        'song.id',
        'Online song does not contain a YouTube video ID.',
      );
    }

    try {
      await _stopCurrentPlayback();

      final playableSong = Song(
        id: song.id,
        title: song.title,
        artist: song.artist,
        album: song.album,
        artwork: song.artwork.isEmpty ? null : song.artwork,
        audioUrl: videoId,
        duration: song.duration,
      );

      final youtubeQueue = queue
          .map(
            (item) => Song(
              id: item.id,
              title: item.title,
              artist: item.artist,
              album: item.album,
              artwork: item.artwork.isEmpty ? null : item.artwork,
              audioUrl: item.id,
              duration: item.duration,
            ),
          )
          .toList();

      _isOnlineQueue = true;

      _engine = _PlaybackEngine.youtube;

      state = state.copyWith(
        currentSong: playableSong,
        queue: youtubeQueue.isEmpty ? [playableSong] : youtubeQueue,
        position: Duration.zero,
        duration: song.duration,
        isPlaying: false,
        isBuffering: true,
      );

      _startYoutubePositionUpdates();
      await _youtube.load(videoId);

      if (_engine == _PlaybackEngine.youtube) {
        state = state.copyWith(isPlaying: true, isBuffering: false);
      }
    } catch (error, stackTrace) {
      debugPrint('Online playback failed: $error');

      debugPrintStack(stackTrace: stackTrace);

      _engine = _PlaybackEngine.none;
      _stopYoutubePositionUpdates();

      state = state.copyWith(isPlaying: false, isBuffering: false);

      rethrow;
    }
  }

  // ===========================================================================
  // STOP CURRENT PLAYBACK
  // ===========================================================================

  Future<void> _stopCurrentPlayback() async {
    await _cancelCrossfadeTransition();

    switch (_engine) {
      case _PlaybackEngine.justAudio:
        await _player.stop();
        break;

      case _PlaybackEngine.youtube:
        _stopYoutubePositionUpdates();
        try {
          await _youtube.pause();
        } catch (_) {}
        break;

      case _PlaybackEngine.none:
        break;
    }

    _engine = _PlaybackEngine.none;
  }

  // ===========================================================================
  // PLAY / PAUSE
  // ===========================================================================

  Future<void> togglePlayPause() async {
    switch (_engine) {
      case _PlaybackEngine.justAudio:
        if (_player.playing) {
          await _player.pause();
        } else if (_player.audioSource != null) {
          await _player.play();
        }
        break;

      case _PlaybackEngine.youtube:
        await _youtube.togglePlayPause();
        break;

      case _PlaybackEngine.none:
        break;
    }
  }

  // ===========================================================================
  // SEEK
  // ===========================================================================

  Future<void> seek(Duration position) async {
    switch (_engine) {
      case _PlaybackEngine.justAudio:
        await _player.seek(position);
        break;

      case _PlaybackEngine.youtube:
        await _youtube.seek(position);
        break;

      case _PlaybackEngine.none:
        break;
    }
  }

  // ===========================================================================
  // QUEUE
  // ===========================================================================

  Future<void> previousSong() async {
    final current = state.currentSong;

    if (current == null || state.queue.isEmpty) {
      return;
    }

    final index = state.queue.indexWhere((song) => song.id == current.id);

    if (index <= 0) {
      return;
    }

    await _playQueueSong(state.queue[index - 1]);
  }

  Future<void> nextSong() async {
    final current = state.currentSong;

    if (current == null || state.queue.isEmpty) {
      return;
    }

    final index = state.queue.indexWhere((song) => song.id == current.id);

    if (index < 0 || index >= state.queue.length - 1) {
      state = state.copyWith(isPlaying: false, position: Duration.zero);

      return;
    }

    await _playQueueSong(state.queue[index + 1]);
  }

  Future<void> _playQueueSong(Song song) async {
    if (_isOnlineQueue) {
      state = state.copyWith(
        currentSong: song,
        position: Duration.zero,
        duration: song.duration,
        isPlaying: false,
        isBuffering: true,
      );

      await _youtube.load(song.audioUrl);
      state = state.copyWith(isPlaying: true, isBuffering: false);
      return;
    }

    await playSong(song, queue: state.queue);
  }

  // ===========================================================================
  // SLEEP TIMER
  // ===========================================================================

  Future<void> setSleepTimer(Duration duration) async {
    _sleepTimer?.cancel();
    _sleepTimer = null;

    if (duration <= Duration.zero) {
      state = state.copyWith(sleepTimerRemaining: Duration.zero);

      return;
    }

    state = state.copyWith(sleepTimerRemaining: duration);

    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final remaining = state.sleepTimerRemaining;

      if (remaining <= const Duration(seconds: 1)) {
        timer.cancel();
        _sleepTimer = null;

        state = state.copyWith(
          sleepTimerRemaining: Duration.zero,
          isPlaying: false,
        );

        switch (_engine) {
          case _PlaybackEngine.justAudio:
            await _player.pause();
            break;

          case _PlaybackEngine.youtube:
            await _youtube.pause();
            break;

          case _PlaybackEngine.none:
            break;
        }

        return;
      }

      state = state.copyWith(
        sleepTimerRemaining: remaining - const Duration(seconds: 1),
      );
    });
  }

  Future<void> cancelSleepTimer() async {
    await setSleepTimer(Duration.zero);
  }

  // ===========================================================================
  // CROSSFADE
  // ===========================================================================

  Future<void> setCrossfadeDuration(Duration duration) async {
    final seconds = duration.inSeconds.clamp(0, 12).toInt();

    _crossfadeTimer?.cancel();
    _crossfadeTimer = null;

    _crossfadeInProgress = false;
    _crossfadeTarget = null;

    await _cancelCrossfadeTransition();

    state = state.copyWith(crossfadeDuration: Duration(seconds: seconds));
  }

  void _maybeStartCrossfade() {
    if (_engine != _PlaybackEngine.justAudio || _isOnlineQueue) {
      return;
    }

    final fade = state.crossfadeDuration;

    if (fade <= Duration.zero ||
        _crossfadeInProgress ||
        state.currentSong == null ||
        state.queue.isEmpty ||
        !_player.playing ||
        _player.duration == null) {
      return;
    }

    final remaining = _player.duration! - _player.position;

    if (remaining <= fade) {
      _startCrossfade();
    }
  }

  Future<void> _startCrossfade() async {
    if (_engine != _PlaybackEngine.justAudio || _isOnlineQueue) {
      return;
    }

    if (_crossfadeInProgress ||
        state.currentSong == null ||
        state.queue.isEmpty ||
        state.crossfadeDuration <= Duration.zero) {
      return;
    }

    final index = state.queue.indexWhere(
      (song) => song.id == state.currentSong!.id,
    );

    if (index < 0 || index >= state.queue.length - 1) {
      return;
    }

    final next = state.queue[index + 1];

    if (next.audioUrl.trim().isEmpty) {
      return;
    }

    _crossfadeInProgress = true;
    _crossfadeTarget = next;

    final fadeDuration = state.crossfadeDuration;

    final transitionEqualizer = ja.AndroidEqualizer();

    final transitionPlayer = ja.AudioPlayer(
      audioPipeline: ja.AudioPipeline(
        androidAudioEffects: [transitionEqualizer],
      ),
    );

    _transitionEqualizer = transitionEqualizer;

    _transitionPlayer = transitionPlayer;

    try {
      await transitionPlayer.setAudioSource(
        ja.AudioSource.uri(_sourceForAudioUrl(next.audioUrl)),
      );

      await transitionPlayer.setVolume(0.0);

      await _applyEqualizerTo(transitionEqualizer, _equalizerLevels);

      await transitionPlayer.play();

      final steps = (fadeDuration.inMilliseconds / 50).ceil().clamp(1, 240);

      final milliseconds = (fadeDuration.inMilliseconds / steps).round().clamp(
        1,
        1000,
      );

      final stepDuration = Duration(milliseconds: milliseconds);

      var step = 0;

      _crossfadeTimer?.cancel();

      _crossfadeTimer = Timer.periodic(stepDuration, (timer) async {
        step++;

        final progress = (step / steps).clamp(0.0, 1.0);

        await _player.setVolume(1.0 - progress);

        await transitionPlayer.setVolume(progress);

        if (step >= steps) {
          timer.cancel();
          _crossfadeTimer = null;

          await _finishCrossfade();
        }
      });
    } catch (error, stackTrace) {
      debugPrint('Crossfade failed: $error');

      debugPrintStack(stackTrace: stackTrace);

      await _cancelCrossfadeTransition();

      _crossfadeInProgress = false;
      _crossfadeTarget = null;
    }
  }

  Future<void> _finishCrossfade() async {
    final nextPlayer = _transitionPlayer;

    final nextEqualizer = _transitionEqualizer;

    final nextSong = _crossfadeTarget;

    if (nextPlayer == null || nextEqualizer == null || nextSong == null) {
      await _cancelCrossfadeTransition();

      _crossfadeInProgress = false;
      _crossfadeTarget = null;

      return;
    }

    final oldPlayer = _player;

    final oldEqualizer = _equalizer;

    await oldPlayer.stop();
    await oldPlayer.dispose();

    try {
      await oldEqualizer.setEnabled(false);
    } catch (_) {}

    _player = nextPlayer;
    _equalizer = nextEqualizer;

    _transitionPlayer = null;
    _transitionEqualizer = null;

    _crossfadeTarget = null;
    _crossfadeInProgress = false;

    state = state.copyWith(
      currentSong: nextSong,
      position: _player.position,
      duration: _player.duration ?? nextSong.duration,
      isPlaying: _player.playing,
    );
  }

  Future<void> _cancelCrossfadeTransition() async {
    _crossfadeTimer?.cancel();
    _crossfadeTimer = null;

    final transition = _transitionPlayer;

    final transitionEqualizer = _transitionEqualizer;

    _transitionPlayer = null;
    _transitionEqualizer = null;

    if (transition != null) {
      try {
        await transition.stop();
      } catch (_) {}

      try {
        await transition.dispose();
      } catch (_) {}
    }

    if (transitionEqualizer != null) {
      try {
        await transitionEqualizer.setEnabled(false);
      } catch (_) {}
    }

    _crossfadeInProgress = false;
    _crossfadeTarget = null;
  }

  // ===========================================================================
  // EQUALIZER
  // ===========================================================================

  Future<void> setEqualizerLevels(List<double> levels) async {
    if (levels.length != 5) {
      throw ArgumentError.value(
        levels.length,
        'levels',
        'Aurora equalizer requires exactly 5 bands.',
      );
    }

    _equalizerLevels = levels
        .map((value) => value.clamp(-12.0, 12.0).toDouble())
        .toList(growable: false);

    await _applyEqualizerTo(_equalizer, _equalizerLevels);

    if (_transitionEqualizer != null) {
      await _applyEqualizerTo(_transitionEqualizer!, _equalizerLevels);
    }
  }

  Future<void> _applyEqualizerTo(
    ja.AndroidEqualizer equalizer,
    List<double> levels,
  ) async {
    try {
      await equalizer.setEnabled(true);

      final parameters = await equalizer.parameters;

      final bands = parameters.bands;

      if (bands.isEmpty) {
        return;
      }

      for (var i = 0; i < bands.length; i++) {
        final sourceIndex = bands.length == 1
            ? 0
            : (i * (levels.length - 1) / (bands.length - 1)).round().clamp(
                0,
                levels.length - 1,
              );

        await bands[i].setGain(levels[sourceIndex]);
      }
    } catch (error, stackTrace) {
      debugPrint('Equalizer unavailable: $error');

      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> resetEqualizer() async {
    await setEqualizerLevels(List<double>.filled(5, 0.0));
  }

  // ===========================================================================
  // SHUFFLE
  // ===========================================================================

  Future<void> toggleShuffle() async {
    final enabled = !state.isShuffleEnabled;

    if (_engine == _PlaybackEngine.justAudio) {
      await _player.setShuffleModeEnabled(enabled);
    }

    state = state.copyWith(isShuffleEnabled: enabled);
  }

  // ===========================================================================
  // REPEAT
  // ===========================================================================

  Future<void> cycleRepeatMode() async {
    switch (state.repeatMode) {
      case PlayerRepeatMode.off:
        if (_engine == _PlaybackEngine.justAudio) {
          await _player.setLoopMode(ja.LoopMode.all);
        }

        state = state.copyWith(repeatMode: PlayerRepeatMode.all);

        break;

      case PlayerRepeatMode.all:
        if (_engine == _PlaybackEngine.justAudio) {
          await _player.setLoopMode(ja.LoopMode.one);
        }

        state = state.copyWith(repeatMode: PlayerRepeatMode.one);

        break;

      case PlayerRepeatMode.one:
        if (_engine == _PlaybackEngine.justAudio) {
          await _player.setLoopMode(ja.LoopMode.off);
        }

        state = state.copyWith(repeatMode: PlayerRepeatMode.off);

        break;
    }
  }

  // ===========================================================================
  // DISPOSE
  // ===========================================================================

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _youtubeValueSubscription?.cancel();

    _youtubePositionTimer?.cancel();
    _sleepTimer?.cancel();
    _crossfadeTimer?.cancel();

    _transitionPlayer?.dispose();

    _transitionEqualizer?.setEnabled(false);

    _youtube.dispose();
    _player.dispose();

    _equalizer.setEnabled(false);

    super.dispose();
  }
}

// ==============================================================================
// PROVIDER
// ==============================================================================

final playerControllerProvider =
    StateNotifierProvider<PlayerController, PlayerState>((ref) {
      return PlayerController();
    });
