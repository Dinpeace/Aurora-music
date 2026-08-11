from pathlib import Path

path = Path("lib/features/search/search_screen.dart")

if not path.exists():
    raise SystemExit("ERROR: Run this from ~/aurora_music")

text = path.read_text(encoding="utf-8")

old = "separatorBuilder: (_, _) => const SizedBox(height: 8),"
new = "separatorBuilder: (context, index) => const SizedBox(height: 8),"

if old in text:
    path.write_text(text.replace(old, new, 1), encoding="utf-8")
    print("Modified: lib/features/search/search_screen.dart")
else:
    print("No matching lint pattern found.")
    print("Your Search Favorites integration may already be clean.")

print("Next: flutter analyze")
