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
    final raw = json['songs'];

    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          songs.add(
            FavoriteItem.fromJson(Map<String, dynamic>.from(item)),
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

  static const _key = 'aurora.playlists';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final playlists = <AuroraPlaylist>[];

    for (final value in prefs.getStringList(_key) ?? const <String>[]) {
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
        // Ignore malformed saved playlists.
      }
    }

    state = PlaylistState(
      playlists: playlists,
      loading: false,
    );
  }

  Future<void> create(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return;
    }

    final playlist = AuroraPlaylist(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: trimmedName,
      songs: const [],
      createdAt: DateTime.now(),
    );

    final playlists = [playlist, ...state.playlists];
    state = state.copyWith(
      playlists: playlists,
      loading: false,
    );
    await _save(playlists);
  }

  Future<void> rename(String id, String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return;
    }

    final playlists = state.playlists
        .map(
          (playlist) => playlist.id == id
              ? playlist.copyWith(name: trimmedName)
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

  Future<void> addSong(String playlistId, FavoriteItem song) async {
    final playlists = state.playlists
        .map((playlist) {
          if (playlist.id != playlistId ||
              playlist.songs.any((item) => item.id == song.id)) {
            return playlist;
          }

          return playlist.copyWith(
            songs: [...playlist.songs, song],
          );
        })
        .toList(growable: false);

    state = state.copyWith(
      playlists: playlists,
      loading: false,
    );
    await _save(playlists);
  }

  Future<void> removeSong(String playlistId, String songId) async {
    final playlists = state.playlists
        .map(
          (playlist) => playlist.id == playlistId
              ? playlist.copyWith(
                  songs: playlist.songs
                      .where((song) => song.id != songId)
                      .toList(growable: false),
                )
              : playlist,
        )
        .toList(growable: false);

    state = state.copyWith(
      playlists: playlists,
      loading: false,
    );
    await _save(playlists);
  }

  Future<void> _save(List<AuroraPlaylist> playlists) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
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
