DIRECT DART REPLACEMENT — package imports

Replace these 3 files in:
~/aurora_music/lib/features/library/

playlist_provider.dart
playlists_screen.dart
favorite_playback_screen.dart

These use package:aurora_music/... imports based on your pubspec.yaml.

Then run:
flutter analyze

No Python patch is required.
