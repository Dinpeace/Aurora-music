from pathlib import Path
import shutil

root = Path.cwd()

files = {
    "playlist_provider.dart": root / "lib/features/library/playlist_provider.dart",
    "playlists_screen.dart": root / "lib/features/library/playlists_screen.dart",
    "favorite_playback_screen.dart": root / "lib/features/library/favorite_playback_screen.dart",
}

for name, destination in files.items():
    source = Path(__file__).parent / name
    if not source.exists():
        raise SystemExit(f"Missing patch file: {source}")
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, destination)
    print("Installed:", destination)

print()
print("Bulk Pack 1 files installed.")
print()
print("Run:")
print("  flutter analyze")
print()
print("Then:")
print("  flutter run")
print()
print("This pack intentionally does not modify your app's navigation shell,")
print("because that structure was not provided. The new screens can be wired")
print("into your existing navigation without replacing it.")
