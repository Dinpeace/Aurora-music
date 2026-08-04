import 'package:flutter/material.dart';

class MusicCard extends StatelessWidget {
  final String title;
  final String artist;
  final String image;
  final VoidCallback? onTap;

  const MusicCard({
    super.key,
    required this.title,
    required this.artist,
    required this.image,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 165,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: title,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.asset(
                  image,
                  width: 165,
                  height: 165,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 165,
                      height: 165,
                      decoration: BoxDecoration(
                        color: const Color(0xFF18181B),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.music_note_rounded,
                          size: 60,
                          color: Color(0xFFA855F7),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 12),

            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}