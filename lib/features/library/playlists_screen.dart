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
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Create playlist',
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _createPlaylist(context, ref),
          ),
        ],
      ),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : state.playlists.isEmpty
              ? _EmptyPlaylists(
                  onCreate: () => _createPlaylist(context, ref),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  itemCount: state.playlists.length,
                  separatorBuilder: (_, index) => const Divider(
                    color: Color(0xFF27272A),
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final playlist = state.playlists[index];

                    return ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 5),
                      leading: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFA855F7),
                              Color(0xFF22D3EE),
                            ],
                          ),
                        ),
                        child: const Icon(
                          Icons.queue_music_rounded,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        playlist.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '${playlist.songs.length} ${playlist.songs.length == 1 ? 'song' : 'songs'}',
                        style: const TextStyle(color: Colors.white60),
                      ),
                      onTap: () => _openPlaylist(
                        context,
                        playlist.id,
                      ),
                      trailing: PopupMenuButton<String>(
                        color: const Color(0xFF27272A),
                        onSelected: (value) async {
                          if (value == 'rename') {
                            await _renamePlaylist(
                              context,
                              ref,
                              playlist.id,
                              playlist.name,
                            );
                          } else if (value == 'delete') {
                            await ref
                                .read(playlistProvider.notifier)
                                .delete(playlist.id);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'rename',
                            child: Text(
                              'Rename',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
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

  Future<void> _createPlaylist(
    BuildContext context,
    WidgetRef ref,
  ) async {
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
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Playlist name',
            hintStyle: TextStyle(color: Colors.white38),
          ),
          onSubmitted: (value) => Navigator.pop(
            dialogContext,
            value.trim(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFA855F7),
            ),
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

    if (name != null && name.trim().isNotEmpty) {
      await ref.read(playlistProvider.notifier).create(name);
    }
  }

  Future<void> _renamePlaylist(
    BuildContext context,
    WidgetRef ref,
    String id,
    String currentName,
  ) async {
    final controller = TextEditingController(text: currentName);

    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        title: const Text(
          'Rename playlist',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFA855F7),
            ),
            onPressed: () => Navigator.pop(
              dialogContext,
              controller.text.trim(),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (name != null && name.trim().isNotEmpty) {
      await ref.read(playlistProvider.notifier).rename(id, name);
    }
  }

  void _openPlaylist(
    BuildContext context,
    String playlistId,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlaylistDetailScreen(
          playlistId: playlistId,
        ),
      ),
    );
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

    final selectedPlaylist = playlist;

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        title: Text(selectedPlaylist.name),
        backgroundColor: const Color(0xFF09090B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: selectedPlaylist.songs.isEmpty
          ? const Center(
              child: Text(
                'No songs in this playlist yet.',
                style: TextStyle(color: Colors.white60),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              itemCount: selectedPlaylist.songs.length,
              separatorBuilder: (_, index) => const Divider(
                color: Color(0xFF27272A),
                height: 1,
              ),
              itemBuilder: (context, index) {
                final song = selectedPlaylist.songs[index];

                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 4),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: song.artwork.isNotEmpty
                        ? Image.network(
                            song.artwork,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) =>
                                    _placeholder(),
                          )
                        : _placeholder(),
                  ),
                  title: Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white60),
                  ),
                  trailing: IconButton(
                    tooltip: 'Remove',
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.white54,
                    ),
                    onPressed: () => ref
                        .read(playlistProvider.notifier)
                        .removeSong(
                          selectedPlaylist.id,
                          song.id,
                        ),
                  ),
                );
              },
            ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        gradient: LinearGradient(
          colors: [
            Color(0xFFA855F7),
            Color(0xFF22D3EE),
          ],
        ),
      ),
      child: const Icon(
        Icons.music_note_rounded,
        color: Colors.white,
      ),
    );
  }
}

class _EmptyPlaylists extends StatelessWidget {
  const _EmptyPlaylists({
    required this.onCreate,
  });

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.queue_music_rounded,
              color: Color(0xFFA855F7),
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'No playlists yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a playlist to organize your music.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFA855F7),
              ),
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create playlist'),
            ),
          ],
        ),
      ),
    );
  }
}
