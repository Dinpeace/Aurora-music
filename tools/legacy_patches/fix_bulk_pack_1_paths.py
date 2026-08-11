from pathlib import Path
import os
import re

root = Path.cwd()
lib = root / "lib"

if not lib.exists():
    raise SystemExit("ERROR: lib/ not found. Run this from ~/aurora_music.")

targets = {
    "favorite_provider.dart": None,
    "online_song.dart": None,
    "player_controller.dart": None,
}

for filename in targets:
    matches = list(lib.rglob(filename))
    if not matches:
        raise SystemExit(
            f"ERROR: Could not find lib/**/{filename}. "
            "No changes were made."
        )
    if len(matches) > 1:
        print(f"WARNING: Multiple {filename} files found:")
        for match in matches:
            print("  ", match)
        print("Using:", matches[0])
    targets[filename] = matches[0]

files = [
    lib / "features/library/favorite_playback_screen.dart",
    lib / "features/library/playlist_provider.dart",
    lib / "features/library/playlists_screen.dart",
]

for path in files:
    if not path.exists():
        print("SKIP (not found):", path)
        continue

    text = path.read_text(encoding="utf-8")

    def rel_import(target):
        rel = os.path.relpath(target, path.parent).replace(os.sep, "/")
        if not rel.startswith("."):
            rel = "./" + rel
        return rel

    # Replace any import that ends in the known filename, regardless of
    # what the previous patch wrote.
    replacements = {
        "favorite_provider.dart": rel_import(targets["favorite_provider.dart"]),
        "online_song.dart": rel_import(targets["online_song.dart"]),
        "player_controller.dart": rel_import(targets["player_controller.dart"]),
    }

    for filename, import_path in replacements.items():
        pattern = rf"import\s+['\"][^'\"]*{re.escape(filename)}['\"]\s*;"
        text = re.sub(
            pattern,
            f"import '{import_path}';",
            text,
        )

    # Remove the unused FavoriteProvider import from playlists_screen.dart
    # only if the file doesn't actually reference FavoriteItem/provider.
    if path.name == "playlists_screen.dart":
        if "FavoriteItem" not in text and "favoriteProvider" not in text:
            fp = replacements["favorite_provider.dart"]
            text = re.sub(
                rf"import\s+['\"][^'\"]*{re.escape('favorite_provider.dart')}['\"]\s*;\s*\n?",
                "",
                text,
            )

    # Fix the nullable firstWhere/cast expression in PlaylistDetailScreen.
    old = """final playlist = state.playlists.cast<AuroraPlaylist?>().firstWhere(
          (item) => item?.id == playlistId,
          orElse: () => null,
        );"""
    new = """AuroraPlaylist? playlist;
    for (final item in state.playlists) {
      if (item.id == playlistId) {
        playlist = item;
        break;
      }
    }"""
    text = text.replace(old, new)

    path.write_text(text, encoding="utf-8")
    print("Patched:", path)

print()
print("Import paths were rebuilt from the actual files in your project.")
print("Nullable playlist lookup was also fixed.")
print()
print("Now run:")
print("  flutter analyze")
