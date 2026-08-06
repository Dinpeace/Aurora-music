import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        title: const Text("Library"),
        backgroundColor: const Color(0xFF09090B),
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
                "Permission required",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          if (library.songs.isEmpty) {
            return const Center(
              child: Text(
                "No music found",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return ListView.builder(
            itemCount: library.songs.length,
            itemBuilder: (context, index) {
              final song = library.songs[index];

              return ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.music_note),
                ),
                title: Text(
                  song.title,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  song.artist,
                  style: const TextStyle(color: Colors.white70),
                ),
                onTap: () {
                  // Playback comes next.
                },
              );
            },
          );
        },
      ),
    );
  }
}