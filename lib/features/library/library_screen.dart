import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/song.dart';
import '../player/player_controller.dart';
import 'library_controller.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(libraryControllerProvider.notifier).loadLibrary();
    });
  }

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(libraryControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        title: const Text('Library'),
        backgroundColor: const Color(0xFF09090B),
        elevation: 0,
      ),
      body: Builder(
        builder: (context) {
          if (library.loading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!library.permissionGranted) {
            return const Center(
              child: Text(
                'Storage permission required.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          if (library.songs.isEmpty) {
            return const Center(
              child: Text(
                'No songs found.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: library.songs.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 1),
            itemBuilder: (context, index) {
              final Song song = library.songs[index];

              return ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.music_note),
                ),
                title: Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  song.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                ),
                onTap: () {
                  ref
                      .read(playerControllerProvider.notifier)
                      .playSong(
                        song,
                        queue: library.songs,
                      );
                },
              );
            },
          );
        },
      ),
    );
  }
}