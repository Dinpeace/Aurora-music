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

  final OnlineRepository? _onlineRepository;

  late ja.AndroidEqualizer _equalizer;
  late ja.AudioPlayer _player;
  ja.AudioPlayer? _transitionPlayer;
  ja.AndroidEqualizer? _transitionEqualizer;

  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<ja.PlayerState>? _playerStateSubscription;
  StreamSubscription<ja.PlayerState>? _processingSubscription;
  Timer? _sleepTimer;
  Timer? _crossfadeTimer;

  List<double> _equalizerLevels = List<double>.filled(5, 0.0);
  bool _crossfadeInProgress = false;
  Song? _crossfadeTarget;

  ja.AudioPlayer _createPlayer(ja.AndroidEqualizer equalizer) {
    return ja.AudioPlayer(
      audioPipeline: ja.AudioPipeline(
        androidAudioEffects: [equalizer],
      ),
    );
  }

  void _initializePlayers() {
    _equalizer = ja.AndroidEqualizer();
    _player = _createPlayer(_equalizer);
  }

  void _registerListeners() {
    _initializePlayers();
    _bindActivePlayerListeners();
  }

  void _bindActivePlayerListeners() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _processingSubscription?.cancel();

    _positionSubscription = _player.positionStream.listen((position) {
      state = state.copyWith(position: position);
      _maybeStartCrossfade();
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
      if (playerState.processingState == ja.ProcessingState.completed &&
          !_crossfadeInProgress) {
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

  Future<void> playOnlineSong(
    OnlineSong song, {
    List<OnlineSong> queue = const [],
  }) async {
    final repository = _onlineRepository;
    if (repository == null) {
      throw StateError('Online repository is not configured.');
    }

    try {
      final resolved = song.streamUrl.trim().isNotEmpty
          ? song.streamUrl.trim()
          : (await repository.getStream(song.id)).streamUrl.trim();

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
          .where((item) => item.streamUrl.trim().isNotEmpty)
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
      await _cancelCrossfadeTransition();
      await _player.stop();
      await _player.setVolume(1.0);
      await _player.setAudioSource(ja.AudioSource.uri(source));
      await _player.play();

      state = state.copyWith(
        currentSong: song,
        queue: queue.isEmpty ? [song] : queue,
        isPlaying: true,
        position: Duration.zero,
        duration: _player.duration ?? song.duration,
      );

      await setEqualizerLevels(_equalizerLevels);
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

  Future<void> setSleepTimer(Duration duration) async {
    _sleepTimer?.cancel();
    _sleepTimer = null;

    if (duration <= Duration.zero) {
      state = state.copyWith(sleepTimerRemaining: Duration.zero);
      return;
    }

    state = state.copyWith(sleepTimerRemaining: duration);

    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = state.sleepTimerRemaining;

      if (remaining <= const Duration(seconds: 1)) {
        timer.cancel();
        _sleepTimer = null;
        state = state.copyWith(
          sleepTimerRemaining: Duration.zero,
          isPlaying: false,
        );
        _player.pause();
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

  Future<void> setCrossfadeDuration(Duration duration) async {
    final clampedSeconds = duration.inSeconds.clamp(0, 12).toInt();
    final normalized = Duration(seconds: clampedSeconds);

    _crossfadeTimer?.cancel();
    _crossfadeTimer = null;
    _crossfadeInProgress = false;
    _crossfadeTarget = null;

    await _cancelCrossfadeTransition();

    state = state.copyWith(crossfadeDuration: normalized);
  }

  void _maybeStartCrossfade() {
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
    final transitionPlayer = _createPlayer(transitionEqualizer);
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
      final stepDuration = Duration(
        milliseconds: (fadeDuration.inMilliseconds / steps).round().clamp(1, 1000).toInt(),
      );

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
    await oldEqualizer.setEnabled(false);

    _player = nextPlayer;
    _equalizer = nextEqualizer;
    _transitionPlayer = null;
    _transitionEqualizer = null;
    _crossfadeTarget = null;
    _crossfadeInProgress = false;

    _bindActivePlayerListeners();

    state = state.copyWith(
      currentSong: nextSong,
      position: _player.position,
      duration: _player.duration ?? nextSong.duration,
      isPlaying: _player.playing,
    );

    await _applyEqualizerTo(_equalizer, _equalizerLevels);
  }

  Future<void> _cancelCrossfadeTransition() async {
    _crossfadeTimer?.cancel();
    _crossfadeTimer = null;

    final transition = _transitionPlayer;
    final transitionEqualizer = _transitionEqualizer;
    _transitionPlayer = null;
    _transitionEqualizer = null;

    if (transition != null) {
      await transition.stop();
      await transition.dispose();
    }

    if (transitionEqualizer != null) {
      await transitionEqualizer.setEnabled(false);
    }
  }

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

      for (var bandIndex = 0; bandIndex < bands.length; bandIndex++) {
        final sourceIndex = bands.length == 1
            ? 0
            : (bandIndex * (levels.length - 1) / (bands.length - 1))
                .round()
                .clamp(0, levels.length - 1);
        await bands[bandIndex].setGain(levels[sourceIndex]);
      }
    } catch (error, stackTrace) {
      debugPrint('Equalizer unavailable: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> resetEqualizer() async {
    await setEqualizerLevels(List<double>.filled(5, 0.0));
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
    _sleepTimer?.cancel();
    _crossfadeTimer?.cancel();
    _transitionPlayer?.dispose();
    _transitionEqualizer?.setEnabled(false);
    _player.dispose();
    _equalizer.setEnabled(false);
    super.dispose();
  }
}

final playerControllerProvider =
    StateNotifierProvider<PlayerController, PlayerState>((ref) {
  final repository = ref.watch(onlineRepositoryProvider);
  return PlayerController(onlineRepository: repository);
});
