import 'package:flutter/material.dart';

import 'aurora_glass.dart';

class FeaturedBanner extends StatelessWidget {
  const FeaturedBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 235,
      child: Stack(
        children: [
          // Aurora Glow
          Positioned(
            top: -40,
            right: -20,
            child: Container(
              width: 180,
              height: 180,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x5522D3EE),
              ),
            ),
          ),

          Positioned(
            bottom: -50,
            left: -40,
            child: Container(
              width: 170,
              height: 170,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x55A855F7),
              ),
            ),
          ),

          AuroraGlass(
            child: Row(
              children: [
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "FEATURED PLAYLIST",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          letterSpacing: 1.4,
                        ),
                      ),

                      const SizedBox(height: 18),

                      const Text(
                        "Aurora Vibes",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        "Your daily mix is waiting.",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                        ),
                      ),

                      const Spacer(),

                      FilledButton.icon(
                        onPressed: () {},
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 14,
                          ),
                        ),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text("Play"),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 18),

                Expanded(
                  flex: 4,
                  child: Hero(
                    tag: "aurora_logo",
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(24),
                      child: Image.asset(
                        "assets/logos/aurora_logo.png",
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, _, _) =>
                                const Icon(
                          Icons.music_note,
                          color: Colors.white,
                          size: 90,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}