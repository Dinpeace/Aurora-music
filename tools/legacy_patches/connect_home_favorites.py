from pathlib import Path

PROJECT = Path.cwd()

targets = [
    PROJECT / "lib/features/home/widgets/trending_section.dart",
    PROJECT / "lib/features/home/widgets/new_releases.dart",
    PROJECT / "lib/features/home/widgets/recently_played.dart",
]

for path in targets:
    if not path.exists():
        raise SystemExit(f"ERROR: Missing {path}")

    text = path.read_text(encoding="utf-8")
    original = text

    old = "            image: song.artwork ?? '',\n            onTap: () {"
    new = """            image: song.artwork ?? '',
            favoriteId: song.id,
            favoriteAlbum: song.album,
            favoriteStreamUrl: song.audioUrl,
            favoriteDuration: song.duration,
            favoriteIsOnline: false,
            onTap: () {"""

    if old in text and "favoriteId: song.id" not in text:
        text = text.replace(old, new, 1)

    if text != original:
        path.write_text(text, encoding="utf-8")
        print("Modified:", path)
    elif "favoriteId: song.id" in text:
        print("Already connected:", path)
    else:
        print("WARNING: Could not find MusicCard insertion point:", path)

print()
print("Home Favorites connection complete.")
print("Run: flutter analyze")
print("Then: flutter run")
