import 'package:flutter/material.dart';

import '../../radio/radio_screen.dart';
import '../../../data/services/aurora_radio_service.dart';

class AuroraRadioSection extends StatelessWidget {
  const AuroraRadioSection({super.key});

  @override
  Widget build(BuildContext context) {
    const modes = [
      (
        mode: AuroraRadioMode.personalized,
        title: 'Aurora Radio',
        icon: Icons.auto_awesome,
      ),
      (
        mode: AuroraRadioMode.song,
        title: 'Song Radio',
        icon: Icons.radio,
      ),
      (
        mode: AuroraRadioMode.artist,
        title: 'Artist Radio',
        icon: Icons.person,
      ),
      (
        mode: AuroraRadioMode.mood,
        title: 'Mood Radio',
        icon: Icons.mood,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Aurora Radio',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 116,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: modes.length,
            separatorBuilder: (_, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = modes[index];
              return InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RadioScreen(mode: item.mode),
                    ),
                  );
                },
                child: Container(
                  width: 148,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: const Color(0xFF18181B),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(item.icon, color: const Color(0xFFA855F7)),
                      const SizedBox(height: 10),
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
