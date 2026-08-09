import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/online_repository.dart';
import 'search_state.dart';

class SearchController extends StateNotifier<SearchState> {
  SearchController(this._repository) : super(const SearchState());

  final OnlineRepository _repository;
  Timer? _debounce;

  Future<void> search(String query) async {
    final normalizedQuery = query.trim();
    _debounce?.cancel();

    if (normalizedQuery.isEmpty) {
      state = const SearchState();
      return;
    }

    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => _performSearch(normalizedQuery),
    );
  }

  Future<void> _performSearch(String query) async {
    state = state.copyWith(
      loading: true,
      query: query,
      clearError: true,
    );

    try {
      final songs = await _repository.search(query);

      if (state.query != query) return;

      state = state.copyWith(
        loading: false,
        songs: songs,
      );
    } catch (error) {
      state = state.copyWith(
        loading: false,
        songs: const [],
        error: error.toString(),
      );
    }
  }

  void clear() {
    _debounce?.cancel();
    state = const SearchState();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
