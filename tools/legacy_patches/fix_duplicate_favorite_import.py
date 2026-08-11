from pathlib import Path

path = Path.cwd() / "lib/features/search/search_screen.dart"

if not path.exists():
    raise SystemExit(
        "ERROR: lib/features/search/search_screen.dart not found. "
        "Run this from ~/aurora_music."
    )

text = path.read_text(encoding="utf-8")

import_line = "import '../library/favorite_provider.dart';"
count = text.count(import_line)

if count == 0:
    raise SystemExit(
        "ERROR: favorite_provider.dart import was not found. "
        "No changes made."
    )

if count == 1:
    print("Already fixed: favorite_provider.dart has one import.")
else:
    first = True
    lines = text.splitlines(keepends=True)
    output = []

    for line in lines:
        if line.strip() == import_line:
            if first:
                output.append(line)
                first = False
            else:
                continue
        else:
            output.append(line)

    path.write_text("".join(output), encoding="utf-8")
    print(f"Removed {count - 1} duplicate favorite_provider.dart import(s).")

print()
print("Run:")
print("  flutter analyze")
