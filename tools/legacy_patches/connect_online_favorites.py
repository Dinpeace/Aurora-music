from pathlib import Path

path = Path("lib/features/search/search_screen.dart")

if not path.exists():
    raise SystemExit("ERROR: lib/features/search/search_screen.dart not found. Run from ~/aurora_music.")

text = path.read_text(encoding="utf-8")
original = text

# Ensure the Favorites provider is available.
provider_import = "import '../library/favorite_provider.dart';"
if provider_import not in text:
    # Search screen imports are normally in the same features/search directory.
    marker = "import '../player/player_controller.dart';"
    if marker in text:
        text = text.replace(marker, marker + "\n" + provider_import, 1)
    else:
        raise SystemExit(
            "STOP: Could not safely locate the player import in search_screen.dart. "
            "No changes were made."
        )

# If Search already uses MusicCard, connect its OnlineSong metadata directly.
if "MusicCard(" in text:
    old = """            image: song.artwork,
            onTap: () {"""
    new = """            image: song.artwork,
            favoriteId: song.id,
            favoriteAlbum: song.album,
            favoriteStreamUrl: song.streamUrl,
            favoriteDuration: song.duration,
            favoriteIsOnline: true,
            onTap: () {"""

    if old in text and "favoriteStreamUrl: song.streamUrl" not in text:
        text = text.replace(old, new, 1)
        path.write_text(text, encoding="utf-8")
        print("Modified: lib/features/search/search_screen.dart")
        print("OnlineSong favorites are now connected to the existing MusicCard.")
    elif "favoriteStreamUrl: song.streamUrl" in text:
        print("Already connected: OnlineSong favorites.")
    else:
        # We deliberately do not guess at the search UI.
        if text != original:
            path.write_text(text, encoding="utf-8")
        print(
            "STOP: Search uses MusicCard, but its constructor pattern differs. "
            "No risky edit was made."
        )
else:
    # Undo the import if we added it but cannot safely connect the UI.
    if text != original and provider_import in text:
        text = text.replace("\n" + provider_import, "", 1)
    print(
        "STOP: search_screen.dart does not use MusicCard. "
        "No changes were made because the OnlineSong result UI must be connected "
        "using its actual widget structure."
    )

print()
print("Run: flutter analyze")
