from pathlib import Path
import re

project = Path.cwd()
path = project / "lib/features/search/search_screen.dart"

if not path.exists():
    raise SystemExit("ERROR: lib/features/search/search_screen.dart not found. Run from ~/aurora_music.")

text = path.read_text(encoding="utf-8")
original = text

# Remove the previously added unused helper; the tile will use the provider directly.
text = re.sub(
    r"\n  Future<void> _toggleOnlineFavorite\(OnlineSong song\) async \{.*?\n  \}\n\n(?=  Future<void> _play\()",
    "\n",
    text,
    count=1,
    flags=re.S,
)

# Pass the favorite callback plumbing through _SearchBody.
old = """                songs: state.songs,
                onSongTap: _play,
              ),"""
new = """                songs: state.songs,
                onSongTap: _play,
              ),"""
# No parent callback is needed; the tile uses the provider directly.

# Add FavoriteItem toggle logic by converting the tile to ConsumerWidget.
text = text.replace(
    "class _SearchSongTile extends StatelessWidget {",
    "class _SearchSongTile extends ConsumerWidget {",
    1,
)

text = text.replace(
    "  Widget build(BuildContext context) {\n    final hasArtwork = song.artwork.trim().isNotEmpty;",
    """  Widget build(BuildContext context, WidgetRef ref) {
    final hasArtwork = song.artwork.trim().isNotEmpty;
    final isFavorite = ref.watch(favoriteProvider).items.any(
          (item) => item.id == song.id,
        );""",
    1,
)

# Add the favorite button after the Expanded song text area.
anchor = """              Expanded(
                child: Column("""
if anchor not in text:
    raise SystemExit("ERROR: Could not find the search tile's Expanded content.")

# Find the closing of the Expanded block followed by the row close.
pattern = r"(              Expanded\(\n                child: Column\(.*?\n                \),\n              \),)(\n            \],)"
match = re.search(pattern, text, flags=re.S)
if not match:
    raise SystemExit("ERROR: Could not safely locate the end of the search tile text block.")

button = r""",
              IconButton(
                tooltip: isFavorite
                    ? 'Remove from favorites'
                    : 'Add to favorites',
                icon: Icon(
                  isFavorite
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: isFavorite
                      ? Colors.redAccent
                      : Colors.white70,
                ),
                onPressed: () async {
                  final item = FavoriteItem(
                    id: song.id,
                    title: song.title,
                    artist: song.artist,
                    album: song.album,
                    artwork: song.artwork,
                    streamUrl: song.streamUrl,
                    durationMs: song.duration.inMilliseconds,
                    isOnline: true,
                  );

                  await ref
                      .read(favoriteProvider.notifier)
                      .toggle(item);
                },
              )"""
text = text[:match.start(1)] + match.group(1) + button + text[match.end(1):]

if text == original:
    print("Search Favorites UI already patched.")
else:
    path.write_text(text, encoding="utf-8")
    print("Modified:", path)
    print()
    print("Connected the Search OnlineSong tile to the local Favorites provider.")
    print("Run: flutter analyze")

