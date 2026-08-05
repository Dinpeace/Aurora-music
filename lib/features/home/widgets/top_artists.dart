import 'package:flutter/material.dart';

import '../../../shared/widgets/section_title.dart';

class TopArtistsSection extends StatelessWidget {
  const TopArtistsSection({super.key});

  @override
  Widget build(BuildContext context) {
    const artists = [
      "Aurora",
      "The Weeknd",
      "Imagine Dragons",
      "Coldplay",
      "Post Malone",
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          title: "Top Artists",
          onSeeAll: () {},
        ),

        const SizedBox(height: 16),

        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: artists.length,
            separatorBuilder: (_, _) => const SizedBox(width: 18),
            itemBuilder: (_, index) {
              return Column(
                children: [
                  const CircleAvatar(
                    radius: 34,
                    backgroundColor: Color(0xFFA855F7),
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    artists[index],
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}