AURORA MUSIC — FAVORITES PHASE 1

This package adds the guest/local Favorites foundation.

Files:
- favorite_provider.dart -> lib/features/library/favorite_provider.dart
- favorites_screen.dart -> lib/features/library/favorites_screen.dart
- music_card.dart -> lib/shared/widgets/music_card.dart

IMPORTANT:
The new MusicCard keeps backward compatibility. Existing MusicCard calls still compile.

After copying the files, run:
flutter analyze

To make a Home card's heart actually save a song, add these parameters to its MusicCard:
favoriteId: song.id,
favoriteAlbum: song.album,
favoriteStreamUrl: song.audioUrl,
favoriteDuration: song.duration,

For OnlineSong use:
favoriteId: song.id,
favoriteAlbum: song.album,
favoriteStreamUrl: song.streamUrl,
favoriteDuration: song.duration,
favoriteIsOnline: true,

The Favorites screen can be opened with:
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const FavoritesScreen()),
);

Cloud/Firebase sync is NOT included yet.
