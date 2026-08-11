import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/search_provider.dart';
import '../../data/models/online/online_song.dart';
import '../library/favorite_provider.dart';
import '../player/player_controller.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search(String value) {
    ref.read(searchControllerProvider.notifier).search(value);
  }

  Future<void> _play(OnlineSong song, List<OnlineSong> queue) async {
    try {
      await ref.read(playerControllerProvider.notifier).playOnlineSong(
            song,
            queue: queue,
          );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to play this song: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF09090B),
        foregroundColor: Colors.white,
        title: const Text('Search'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: TextField(
                controller: _controller,
                autofocus: true,
                onChanged: _search,
                onSubmitted: _search,
                style: const TextStyle(color: Colors.white),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search songs, artists, albums...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Colors.white54,
                  ),
                  suffixIcon: _controller.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _controller.clear();
                            ref
                                .read(searchControllerProvider.notifier)
                                .clear();
                            setState(() {});
                          },
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white54,
                          ),
                        ),
                  filled: true,
                  fillColor: const Color(0xFF18181B),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _SearchBody(
                loading: state.loading,
                error: state.error,
                query: state.query,
                songs: state.songs,
                onSongTap: _play,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBody extends StatelessWidget {
  const _SearchBody({
    required this.loading,
    required this.error,
    required this.query,
    required this.songs,
    required this.onSongTap,
  });

  final bool loading;
  final String? error;
  final String query;
  final List<OnlineSong> songs;
  final Future<void> Function(OnlineSong song, List<OnlineSong> queue)
      onSongTap;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    if (query.isEmpty) {
      return const Center(
        child: Text(
          'Search for songs, artists, or albums',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    if (songs.isEmpty) {
      return const Center(
        child: Text(
          'No results found',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      itemCount: songs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final song = songs[index];
        return _SearchSongTile(
          song: song,
          onTap: () => onSongTap(song, songs),
        );
      },
    );
  }
}

class _SearchSongTile extends ConsumerWidget {
  const _SearchSongTile({
    required this.song,
    required this.onTap,
  });

  final OnlineSong song;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasArtwork = song.artwork.trim().isNotEmpty;
    final isFavorite = ref.watch(favoriteProvider).items.any(
          (item) => item.id == song.id,
        );

    return Material(
      color: const Color(0xFF18181B),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: hasArtwork
                    ? Image.network(
                        song.artwork,
                        width: 58,
                        height: 58,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _placeholder(),
                      )
                    : _placeholder(),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      song.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white60),
                    ),
                    if (song.album.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        song.album,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: isFavorite
                    ? 'Remove from favorites'
                    : 'Add to favorites',
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.redAccent : Colors.white70,
                ),
                onPressed: () async {
                  final item = FavoriteItem(
                    id: song.id,
                    title: song.title,
                    artist: song.artist,
                    album: song.album,
                    artwork: song.artwork,
                    streamUrl: song.streamUrl,
                    durationMs: song.duration.inMilliseconds,
                    isOnline: true,
                  );
                  await ref.read(favoriteProvider.notifier).toggle(item);
                },
              ),
              const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white70,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 58,
      height: 58,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        gradient: LinearGradient(
          colors: [Color(0xFFA855F7), Color(0xFF22D3EE)],
        ),
      ),
      child: const Icon(
        Icons.music_note_rounded,
        color: Colors.white,
      ),
    );
  }
}
