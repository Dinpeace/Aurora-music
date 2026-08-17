import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/listening_history_entry.dart';
import '../models/song.dart';

/// Persistent local listening history for Aurora's recommendation system.
///
/// The service stores only lightweight playback metadata and the Song fields
/// required to reconstruct recommendation candidates. It is intentionally
/// independent from PlayerController so the player remains the source of
/// playback state.
class ListeningHistoryService {
  ListeningHistoryService({
    SharedPreferences? preferences,
    this.maxEntries = 500,
  }) : _preferences = preferences;

  static const _storageKey = 'aurora_listening_history_v1';

  SharedPreferences? _preferences;
  final int maxEntries;
  List<ListeningHistoryEntry> _entries = const [];

  List<ListeningHistoryEntry> get entries =>
      List<ListeningHistoryEntry>.unmodifiable(_entries);

  Future<void> initialize() async {
    final preferences = _preferences ??=
        await SharedPreferences.getInstance();

    final raw = preferences.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      _entries = const [];
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        _entries = const [];
        return;
      }

      _entries = decoded
          .whereType<Map>()
          .map(
            (item) => ListeningHistoryEntry(
              song: _songFromJson(
                Map<String, dynamic>.from(item['song'] as Map),
              ),
              lastPlayed: DateTime.parse(item['lastPlayed'] as String),
              playCount: (item['playCount'] as num).toInt(),
              position: Duration(
                milliseconds: (item['positionMs'] as num).toInt(),
              ),
              duration: Duration(
                milliseconds: (item['durationMs'] as num).toInt(),
              ),
              skipCount: (item['skipCount'] as num?)?.toInt() ?? 0,
            ),
          )
          .toList(growable: false);
    } catch (_) {
      _entries = const [];
    }
  }

  Future<ListeningHistoryEntry> recordPlay({
    required Song song,
    Duration? position,
    Duration? duration,
    bool skipped = false,
  }) async {
    await _ensureInitialized();

    final id = song.id.trim();
    final index = _entries.indexWhere((entry) => entry.song.id == id);
    final now = DateTime.now();
    final existing = index >= 0 ? _entries[index] : null;

    final entry = ListeningHistoryEntry(
      song: song,
      lastPlayed: now,
      playCount: (existing?.playCount ?? 0) + 1,
      position: position ?? duration ?? song.duration,
      duration: duration ?? song.duration,
      skipCount: (existing?.skipCount ?? 0) + (skipped ? 1 : 0),
    );

    final updated = _entries.toList();
    if (index >= 0) {
      updated[index] = entry;
    } else {
      updated.add(entry);
    }

    updated.sort((a, b) => b.lastPlayed.compareTo(a.lastPlayed));

    _entries = updated.take(maxEntries).toList(growable: false);
    await _save();

    return entry;
  }

  Future<ListeningHistoryEntry> recordSkip({
    required Song song,
    Duration? position,
    Duration? duration,
  }) {
    return recordPlay(
      song: song,
      position: position,
      duration: duration,
      skipped: true,
    );
  }

  Future<void> clear() async {
    await _ensureInitialized();
    _entries = const [];
    await _preferences!.remove(_storageKey);
  }

  Future<void> _ensureInitialized() async {
    if (_preferences == null) {
      await initialize();
    }
  }

  Future<void> _save() async {
    final encoded = _entries.map((entry) {
      return {
        'song': _songToJson(entry.song),
        'lastPlayed': entry.lastPlayed.toIso8601String(),
        'playCount': entry.playCount,
        'positionMs': entry.position.inMilliseconds,
        'durationMs': entry.duration.inMilliseconds,
        'skipCount': entry.skipCount,
      };
    }).toList();

    await _preferences!.setString(_storageKey, jsonEncode(encoded));
  }

  Map<String, dynamic> _songToJson(Song song) {
    return {
      'id': song.id,
      'title': song.title,
      'artist': song.artist,
      'album': song.album,
      'artwork': song.artwork,
      'audioUrl': song.audioUrl,
      'durationMs': song.duration.inMilliseconds,
      'favorite': song.favorite,
    };
  }

  Song _songFromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      artist: json['artist'] as String? ?? '',
      album: json['album'] as String? ?? '',
      artwork: json['artwork'] as String?,
      audioUrl: json['audioUrl'] as String? ?? '',
      duration: Duration(
        milliseconds: (json['durationMs'] as num?)?.toInt() ?? 0,
      ),
      favorite: json['favorite'] as bool? ?? false,
    );
  }
}
