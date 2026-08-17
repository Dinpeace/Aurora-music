import 'package:flutter/material.dart';

import '../../intelligence/intelligence_dashboard_screen.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 24,
          backgroundColor: Color(0xFFA855F7),
          child: Icon(
            Icons.music_note,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Text(
            'Aurora Music',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Aurora Intelligence',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const IntelligenceDashboardScreen(),
              ),
            );
          },
          icon: const Icon(
            Icons.auto_awesome,
            color: Color(0xFFC084FC),
          ),
        ),
        IconButton(
          tooltip: 'Notifications',
          onPressed: () {},
          icon: const Icon(
            Icons.notifications_none,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
