from pathlib import Path
import re

path = Path.cwd() / "lib/features/search/search_screen.dart"

if not path.exists():
    raise SystemExit("ERROR: search_screen.dart not found. Run from ~/aurora_music.")

text = path.read_text(encoding="utf-8")

if "features/library/favorite_provider.dart" not in text:
    anchor = "import '../../data/models/online/online_song.dart';"
    if anchor not in text:
        raise SystemExit("ERROR: Could not find OnlineSong import.")
    text = text.replace(
        anchor,
        anchor + "\nimport '../library/favorite_provider.dart';",
        1,
    )

text = re.sub(
    r"\n\s*Future<void> _toggleOnlineFavorite\(OnlineSong song\) async \{.*?\n\s*\}\n",
    "\n",
    text,
    count=1,
    flags=re.S,
)

start = text.find("class _SearchSongTile extends")
if start == -1:
    start = text.find("class _SearchSongTile")
if start == -1:
    raise SystemExit("ERROR: _SearchSongTile not found.")

opening = text.find("{", start)
if opening == -1:
    raise SystemExit("ERROR: Could not find class opening brace.")

def find_class_end(source, opening):
    depth = 0
    i = opening
    quote = None
    escape = False
    line_comment = False
    block_comment = False
    while i < len(source):
        c = source[i]
        n = source[i + 1] if i + 1 < len(source) else ""
        if line_comment:
            if c == "\n":
                line_comment = False
            i += 1
            continue
        if block_comment:
            if c == "*" and n == "/":
                block_comment = False
                i += 2
                continue
            i += 1
            continue
        if quote:
            if escape:
                escape = False
            elif c == "\\":
                escape = True
            elif c == quote:
                quote = None
            i += 1
            continue
        if c == "/" and n == "/":
            line_comment = True
            i += 2
            continue
        if c == "/" and n == "*":
            block_comment = True
            i += 2
            continue
        if c in ("'", '"'):
            quote = c
            i += 1
            continue
        if c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0:
                return i
        i += 1
    return -1

end = find_class_end(text, opening)
if end == -1:
    raise SystemExit("ERROR: Could not safely parse _SearchSongTile.")

replacement = """class _SearchSongTile extends ConsumerWidget {
  const _SearchSongTile({
    required this.song,
    required this.onTap,
  });

  final OnlineSong song;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasArtwork = song.artwork.trim().isNotEmpty;
    final isFavorite = ref.watch(favoriteProvider).items.any(
          (item) => item.id == song.id,
        );

    return Material(
      color: const Color(0xFF18181B),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: hasArtwork
                    ? Image.network(
                        song.artwork,
                        width: 58,
                        height: 58,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _placeholder(),
                      )
                    : _placeholder(),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      song.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white60),
                    ),
                    if (song.album.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        song.album,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: isFavorite
                    ? 'Remove from favorites'
                    : 'Add to favorites',
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.redAccent : Colors.white70,
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
                  await ref.read(favoriteProvider.notifier).toggle(item);
                },
              ),
              const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white70,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 58,
      height: 58,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        gradient: LinearGradient(
          colors: [Color(0xFFA855F7), Color(0xFF22D3EE)],
        ),
      ),
      child: const Icon(
        Icons.music_note_rounded,
        color: Colors.white,
      ),
    );
  }
}"""

text = text[:start] + replacement + text[end + 1:]
path.write_text(text, encoding="utf-8")
print("Modified:", path)
print("Run: flutter analyze")
