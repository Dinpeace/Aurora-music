import 'package:flutter/material.dart';

class FeaturedBanner extends StatelessWidget {
  const FeaturedBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFA855F7),
            Color(0xFF7C6CF8),
            Color(0xFF22D3EE),
          ],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "FEATURED PLAYLIST",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    letterSpacing: 1.2,
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  "Aurora Vibes",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  "Your daily mix is waiting.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),

                const Spacer(),

                FilledButton.icon(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text("Play Now"),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            flex: 4,
            child: Center(
              child: Image.asset(
                "assets/logos/aurora_logo.png",
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.music_note,
                  color: Colors.white,
                  size: 90,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}