import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteItem {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String artwork;
  final String streamUrl;
  final int durationMs;
  final bool isOnline;

  const FavoriteItem({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.artwork,
    required this.streamUrl,
    required this.durationMs,
    required this.isOnline,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'album': album,
        'artwork': artwork,
        'streamUrl': streamUrl,
        'durationMs': durationMs,
        'isOnline': isOnline,
      };

  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    return FavoriteItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Unknown Title',
      artist: json['artist']?.toString() ?? 'Unknown Artist',
      album: json['album']?.toString() ?? 'Unknown Album',
      artwork: json['artwork']?.toString() ?? '',
      streamUrl: json['streamUrl']?.toString() ?? '',
      durationMs: (json['durationMs'] as num?)?.toInt() ?? 0,
      isOnline: json['isOnline'] == true,
    );
  }
}

class FavoriteState {
  final List<FavoriteItem> items;
  final bool loading;

  const FavoriteState({
    this.items = const [],
    this.loading = true,
  });

  FavoriteState copyWith({
    List<FavoriteItem>? items,
    bool? loading,
  }) {
    return FavoriteState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
    );
  }
}

class FavoriteController extends StateNotifier<FavoriteState> {
  FavoriteController() : super(const FavoriteState()) {
    load();
  }

  static const _storageKey = 'aurora.favorite_items';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? const <String>[];
    final items = <FavoriteItem>[];

    for (final value in raw) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map<String, dynamic> && decoded['id'] != null) {
          items.add(FavoriteItem.fromJson(decoded));
        }
      } catch (_) {}
    }

    state = FavoriteState(items: items, loading: false);
  }

  bool isFavorite(String id) {
    return state.items.any((item) => item.id == id);
  }

  Future<void> toggle(FavoriteItem item) async {
    final items = List<FavoriteItem>.from(state.items);
    final index = items.indexWhere((existing) => existing.id == item.id);

    if (index >= 0) {
      items.removeAt(index);
    } else {
      items.insert(0, item);
    }

    state = state.copyWith(items: items, loading: false);
    await _save(items);
  }

  Future<void> remove(String id) async {
    final items = state.items.where((item) => item.id != id).toList();
    state = state.copyWith(items: items, loading: false);
    await _save(items);
  }

  Future<void> clear() async {
    state = state.copyWith(items: const [], loading: false);
    await _save(const []);
  }

  Future<void> _save(List<FavoriteItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _storageKey,
      items.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }
}

final favoriteProvider =
    StateNotifierProvider<FavoriteController, FavoriteState>(
  (ref) => FavoriteController(),
);
