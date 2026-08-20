import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/song.dart';

/// Playback session persistence for Aurora.
///
/// This is an additive service. It does not modify PlayerController or
/// PlayerState, so the existing v1-v60 Smart Queue baseline remains untouched.
///
/// The service stores only the minimum state required to restore a playback
/// session: current song, queue, position, and playback preferences.
class PlaybackSessionPersistenceService {
  PlaybackSessionPersistenceService({
    SharedPreferences? preferences,
  }) : _preferences = preferences;

  static const String _storageKey = 'aurora_playback_session_v1';

  final SharedPreferences? _preferences;

  Future<SharedPreferences> _prefs() async =>
      _preferences ?? await SharedPreferences.getInstance();

  Future<void> save({
    required Song? currentSong,
    required List<Song> queue,
    required Duration position,
    required bool shuffleEnabled,
    required String repeatMode,
    required Duration crossfadeDuration,
  }) async {
    final prefs = await _prefs();

    final payload = <String, dynamic>{
      'version': 1,
      'currentSong': currentSong == null ? null : _songToJson(currentSong),
      'queue': queue.map(_songToJson).toList(growable: false),
      'positionMs': position.inMilliseconds.clamp(0, 86400000),
      'shuffleEnabled': shuffleEnabled,
      'repeatMode': repeatMode,
      'crossfadeMs': crossfadeDuration.inMilliseconds.clamp(0, 12000),
    };

    await prefs.setString(_storageKey, jsonEncode(payload));
  }

  Future<PlaybackSessionSnapshot?> load() async {
    final prefs = await _prefs();
    final raw = prefs.getString(_storageKey);

    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! Map) {
        return null;
      }

      final version = decoded['version'];
      if (version != 1) {
        return null;
      }

      final queueValue = decoded['queue'];
      final queue = <Song>[];

      if (queueValue is List) {
        for (final item in queueValue) {
          if (item is Map) {
            final song = _songFromJson(item);
            if (song != null) {
              queue.add(song);
            }
          }
        }
      }

      Song? currentSong;
      final currentValue = decoded['currentSong'];
      if (currentValue is Map) {
        currentSong = _songFromJson(currentValue);
      }

      final positionMs = _safeInt(decoded['positionMs']);
      final crossfadeMs = _safeInt(decoded['crossfadeMs']);

      return PlaybackSessionSnapshot(
        currentSong: currentSong,
        queue: List<Song>.unmodifiable(queue),
        position: Duration(milliseconds: positionMs.clamp(0, 86400000)),
        shuffleEnabled: decoded['shuffleEnabled'] == true,
        repeatMode: _safeString(decoded['repeatMode'], 'off'),
        crossfadeDuration: Duration(
          milliseconds: crossfadeMs.clamp(0, 12000),
        ),
      );
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    final prefs = await _prefs();
    await prefs.remove(_storageKey);
  }

  Map<String, dynamic> _songToJson(Song song) => <String, dynamic>{
        'id': song.id,
        'title': song.title,
        'artist': song.artist,
        'album': song.album,
        'artwork': song.artwork,
        'audioUrl': song.audioUrl,
        'durationMs': song.duration.inMilliseconds,
        'favorite': song.favorite,
      };

  Song? _songFromJson(Map value) {
    final id = _safeString(value['id'], '');
    final title = _safeString(value['title'], '');
    final artist = _safeString(value['artist'], '');
    final album = _safeString(value['album'], '');
    final audioUrl = _safeString(value['audioUrl'], '');

    if (id.isEmpty || title.isEmpty || audioUrl.isEmpty) {
      return null;
    }

    return Song(
      id: id,
      title: title,
      artist: artist,
      album: album,
      artwork: _nullableString(value['artwork']),
      audioUrl: audioUrl,
      duration: Duration(
        milliseconds: _safeInt(value['durationMs']).clamp(0, 86400000),
      ),
      favorite: value['favorite'] == true,
    );
  }

  int _safeInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  String _safeString(dynamic value, String fallback) {
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    return fallback;
  }

  String? _nullableString(dynamic value) =>
      value is String && value.trim().isNotEmpty ? value : null;
}

class PlaybackSessionSnapshot {
  const PlaybackSessionSnapshot({
    required this.currentSong,
    required this.queue,
    required this.position,
    required this.shuffleEnabled,
    required this.repeatMode,
    required this.crossfadeDuration,
  });

  final Song? currentSong;
  final List<Song> queue;
  final Duration position;
  final bool shuffleEnabled;
  final String repeatMode;
  final Duration crossfadeDuration;
}
