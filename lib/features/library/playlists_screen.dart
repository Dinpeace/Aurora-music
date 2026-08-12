import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aurora_music/features/library/playlist_provider.dart';

class PlaylistsScreen extends ConsumerWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playlistProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        title: const Text('Playlists'),
        backgroundColor: const Color(0xFF09090B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _create(context, ref),
          ),
        ],
      ),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : state.playlists.isEmpty
              ? _Empty(onCreate: () => _create(context, ref))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.playlists.length,
                  separatorBuilder: (context, index) =>
                      const Divider(color: Color(0xFF27272A)),
                  itemBuilder: (context, index) {
                    final playlist = state.playlists[index];

                    return ListTile(
                      leading: const Icon(
                        Icons.queue_music,
                        color: Color(0xFFA855F7),
                      ),
                      title: Text(
                        playlist.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        '${playlist.songs.length} songs',
                        style: const TextStyle(color: Colors.white60),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlaylistDetailScreen(
                              playlistId: playlist.id,
                            ),
                          ),
                        );
                      },
                      trailing: PopupMenuButton<String>(
                        color: const Color(0xFF27272A),
                        onSelected: (value) {
                          if (value == 'delete') {
                            ref
                                .read(playlistProvider.notifier)
                                .delete(playlist.id);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              'Delete',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        title: const Text(
          'New playlist',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Playlist name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              controller.text.trim(),
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (name != null) {
      await ref.read(playlistProvider.notifier).create(name);
    }
  }
}

class PlaylistDetailScreen extends ConsumerWidget {
  const PlaylistDetailScreen({
    super.key,
    required this.playlistId,
  });

  final String playlistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playlistProvider);
    AuroraPlaylist? playlist;

    for (final item in state.playlists) {
      if (item.id == playlistId) {
        playlist = item;
        break;
      }
    }

    if (playlist == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF09090B),
        body: Center(
          child: Text(
            'Playlist not found',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final currentPlaylist = playlist;

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        title: Text(currentPlaylist.name),
        backgroundColor: const Color(0xFF09090B),
        foregroundColor: Colors.white,
      ),
      body: currentPlaylist.songs.isEmpty
          ? const Center(
              child: Text(
                'No songs in this playlist yet.',
                style: TextStyle(color: Colors.white60),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: currentPlaylist.songs.length,
              separatorBuilder: (context, index) =>
                  const Divider(color: Color(0xFF27272A)),
              itemBuilder: (context, index) {
                final song = currentPlaylist.songs[index];

                return ListTile(
                  title: Text(
                    song.title,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    song.artist,
                    style: const TextStyle(color: Colors.white60),
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.white54,
                    ),
                    onPressed: () => ref
                        .read(playlistProvider.notifier)
                        .removeSong(currentPlaylist.id, song.id),
                  ),
                );
              },
            ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.queue_music,
            color: Color(0xFFA855F7),
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'No playlists yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('Create playlist'),
          ),
        ],
      ),
    );
  }
}
