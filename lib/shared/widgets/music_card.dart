import 'package:flutter/material.dart';

class MusicCard extends StatelessWidget {
  final String title;
  final String artist;

  /// Empty string means no artwork available.
  final String image;

  final VoidCallback? onTap;
  final bool isFavorite;

  const MusicCard({
    super.key,
    required this.title,
    required this.artist,
    required this.image,
    this.onTap,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
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
                  tag: title,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: hasArtwork
                        ? Image.network(
                            image,
                            width: 170,
                            height: 170,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) {
                              return _placeholder();
                            },
                          )
                        : _placeholder(),
                  ),
                ),

                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Icon(
                      isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: isFavorite
                          ? Colors.redAccent
                          : Colors.white,
                      size: 18,
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
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 13,
              ),
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFA855F7),
            Color(0xFF22D3EE),
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.music_note_rounded,
          color: Colors.white,
          size: 64,
        ),
      ),
    );
  }
}