import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/library/favorite_provider.dart';

class MusicCard extends ConsumerWidget {
  final String title;
  final String artist;
  final String image;
  final Object heroTag;
  final VoidCallback? onTap;
  final bool isFavorite;

  /// Stable song identifier used by the local Favorites system.
  final String? favoriteId;

  /// Metadata saved with a favorite. If omitted, the heart remains visual-only.
  final String favoriteAlbum;
  final String favoriteStreamUrl;
  final Duration favoriteDuration;
  final bool favoriteIsOnline;

  const MusicCard({
    super.key,
    required this.title,
    required this.artist,
    required this.image,
    required this.heroTag,
    this.onTap,
    this.isFavorite = false,
    this.favoriteId,
    this.favoriteAlbum = '',
    this.favoriteStreamUrl = '',
    this.favoriteDuration = Duration.zero,
    this.favoriteIsOnline = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canFavorite = favoriteId != null && favoriteId!.trim().isNotEmpty;
    final storedFavorite = canFavorite
        ? ref.watch(favoriteProvider).items.any((e) => e.id == favoriteId)
        : false;
    final favorite = canFavorite ? storedFavorite : isFavorite;
    final hasArtwork = image.trim().isNotEmpty;

    return SizedBox(
      width: 170,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Hero(
                  tag: heroTag,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: hasArtwork
                        ? Image.network(
                            image,
                            width: 170,
                            height: 170,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _placeholder(),
                          )
                        : _placeholder(),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(50),
                      onTap: canFavorite
                          ? () async {
                              final item = FavoriteItem(
                                id: favoriteId!,
                                title: title,
                                artist: artist,
                                album: favoriteAlbum,
                                artwork: image,
                                streamUrl: favoriteStreamUrl,
                                durationMs: favoriteDuration.inMilliseconds,
                                isOnline: favoriteIsOnline,
                              );
                              await ref
                                  .read(favoriteProvider.notifier)
                                  .toggle(item);
                            }
                          : null,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Icon(
                          favorite ? Icons.favorite : Icons.favorite_border,
                          color: favorite ? Colors.redAccent : Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Color(0xFFA855F7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 170,
      height: 170,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(24)),
        gradient: LinearGradient(
          colors: [Color(0xFFA855F7), Color(0xFF22D3EE)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.music_note_rounded, color: Colors.white, size: 64),
      ),
    );
  }
}
