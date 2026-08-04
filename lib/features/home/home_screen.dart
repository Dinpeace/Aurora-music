import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String getGreeting() {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 12) return 'Good Morning 🌅';
    if (h >= 12 && h < 17) return 'Good Afternoon ☀️';
    if (h >= 17 && h < 21) return 'Good Evening 🌇';
    return 'Good Night 🌙';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Aurora Music'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(getGreeting(),
              style: const TextStyle(color: Colors.white,fontSize: 34,fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('What would you like to hear today?',
              style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 24),
          TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search songs, artists, albums...',
              filled: true,
              fillColor: const Color(0xFF18181B),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [Color(0xFFA855F7), Color(0xFF22D3EE)],
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('FEATURED PLAYLIST',style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 12),
                const Text('Aurora Vibes',style: TextStyle(color: Colors.white,fontSize: 30,fontWeight: FontWeight.bold)),
                const Text('Your daily mix is waiting.',style: TextStyle(color: Colors.white70)),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Play Now'),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.library_music), label: 'Library'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}