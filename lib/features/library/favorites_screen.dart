import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'favorite_provider.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoriteProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        title: const Text('Favorites'),
        backgroundColor: const Color(0xFF09090B),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (favorites.items.isNotEmpty)
            IconButton(
              tooltip: 'Clear favorites',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => _confirmClear(context, ref),
            ),
        ],
      ),
      body: favorites.loading
          ? const Center(child: CircularProgressIndicator())
          : favorites.items.isEmpty
              ? const _EmptyFavorites()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  itemCount: favorites.items.length,
                  separatorBuilder: (_, _) =>
                      const Divider(color: Color(0xFF27272A), height: 1),
                  itemBuilder: (context, index) {
                    final item = favorites.items[index];

                    return ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 6),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: item.artwork.isNotEmpty
                            ? Image.network(
                                item.artwork,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    _artworkPlaceholder(),
                              )
                            : _artworkPlaceholder(),
                      ),
                      title: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        item.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white60),
                      ),
                      trailing: IconButton(
                        tooltip: 'Remove from favorites',
                        icon: const Icon(
                          Icons.favorite,
                          color: Colors.redAccent,
                        ),
                        onPressed: () {
                          ref
                              .read(favoriteProvider.notifier)
                              .remove(item.id);
                        },
                      ),
                    );
                  },
                ),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        title: const Text(
          'Clear favorites?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This removes all locally saved favorites.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFA855F7),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(favoriteProvider.notifier).clear();
    }
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              color: Color(0xFFA855F7),
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              'No favorites yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Tap the heart on a song to save it here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _artworkPlaceholder() {
  return Container(
    width: 56,
    height: 56,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFFA855F7), Color(0xFF22D3EE)],
      ),
    ),
    child: const Icon(Icons.music_note_rounded, color: Colors.white),
  );
}
