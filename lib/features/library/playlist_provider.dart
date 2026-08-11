import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aurora_music/features/library/favorite_provider.dart';

class AuroraPlaylist {
  final String id;
  final String name;
  final List<FavoriteItem> songs;
  final DateTime createdAt;

  const AuroraPlaylist({
    required this.id,
    required this.name,
    required this.songs,
    required this.createdAt,
  });

  AuroraPlaylist copyWith({
    String? id,
    String? name,
    List<FavoriteItem>? songs,
    DateTime? createdAt,
  }) {
    return AuroraPlaylist(
      id: id ?? this.id,
      name: name ?? this.name,
      songs: songs ?? this.songs,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'songs': songs.map((song) => song.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AuroraPlaylist.fromJson(Map<String, dynamic> json) {
    final songs = <FavoriteItem>[];
    final rawSongs = json['songs'];

    if (rawSongs is List) {
      for (final rawSong in rawSongs) {
        if (rawSong is Map) {
          songs.add(
            FavoriteItem.fromJson(
              Map<String, dynamic>.from(rawSong),
            ),
          );
        }
      }
    }

    return AuroraPlaylist(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Playlist',
      songs: songs,
      createdAt: DateTime.tryParse(
            json['createdAt']?.toString() ?? '',
          ) ??
          DateTime.now(),
    );
  }
}

class PlaylistState {
  final List<AuroraPlaylist> playlists;
  final bool loading;

  const PlaylistState({
    this.playlists = const [],
    this.loading = true,
  });

  PlaylistState copyWith({
    List<AuroraPlaylist>? playlists,
    bool? loading,
  }) {
    return PlaylistState(
      playlists: playlists ?? this.playlists,
      loading: loading ?? this.loading,
    );
  }
}

class PlaylistController extends StateNotifier<PlaylistState> {
  PlaylistController() : super(const PlaylistState()) {
    load();
  }

  static const _storageKey = 'aurora.playlists';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? const <String>[];
    final playlists = <AuroraPlaylist>[];

    for (final value in raw) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) {
          final playlist = AuroraPlaylist.fromJson(
            Map<String, dynamic>.from(decoded),
          );

          if (playlist.id.isNotEmpty) {
            playlists.add(playlist);
          }
        }
      } catch (_) {
        // Ignore one malformed playlist and continue loading the rest.
      }
    }

    state = PlaylistState(
      playlists: playlists,
      loading: false,
    );
  }

  Future<void> create(String name) async {
    final clean = name.trim();
    if (clean.isEmpty) return;

    final playlist = AuroraPlaylist(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: clean,
      songs: const [],
      createdAt: DateTime.now(),
    );

    final playlists = <AuroraPlaylist>[
      playlist,
      ...state.playlists,
    ];

    state = state.copyWith(
      playlists: playlists,
      loading: false,
    );

    await _save(playlists);
  }

  Future<void> rename(String id, String name) async {
    final clean = name.trim();
    if (clean.isEmpty) return;

    final playlists = state.playlists
        .map(
          (playlist) => playlist.id == id
              ? playlist.copyWith(name: clean)
              : playlist,
        )
        .toList(growable: false);

    state = state.copyWith(
      playlists: playlists,
      loading: false,
    );

    await _save(playlists);
  }

  Future<void> delete(String id) async {
    final playlists = state.playlists
        .where((playlist) => playlist.id != id)
        .toList(growable: false);

    state = state.copyWith(
      playlists: playlists,
      loading: false,
    );

    await _save(playlists);
  }

  Future<void> addSong(
    String playlistId,
    FavoriteItem song,
  ) async {
    final playlists = state.playlists.map((playlist) {
      if (playlist.id != playlistId) {
        return playlist;
      }

      if (playlist.songs.any((existing) => existing.id == song.id)) {
        return playlist;
      }

      return playlist.copyWith(
        songs: [
          ...playlist.songs,
          song,
        ],
      );
    }).toList(growable: false);

    state = state.copyWith(
      playlists: playlists,
      loading: false,
    );

    await _save(playlists);
  }

  Future<void> removeSong(
    String playlistId,
    String songId,
  ) async {
    final playlists = state.playlists.map((playlist) {
      if (playlist.id != playlistId) {
        return playlist;
      }

      return playlist.copyWith(
        songs: playlist.songs
            .where((song) => song.id != songId)
            .toList(growable: false),
      );
    }).toList(growable: false);

    state = state.copyWith(
      playlists: playlists,
      loading: false,
    );

    await _save(playlists);
  }

  Future<void> _save(List<AuroraPlaylist> playlists) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      _storageKey,
      playlists
          .map((playlist) => jsonEncode(playlist.toJson()))
          .toList(growable: false),
    );
  }
}

final playlistProvider =
    StateNotifierProvider<PlaylistController, PlaylistState>(
  (ref) => PlaylistController(),
);
