import 'package:flutter/material.dart';

import '../../shared/widgets/featured_banner.dart';
import '../../shared/widgets/search_bar.dart';
import '../library/library_screen.dart';
import '../search/search_screen.dart';
import '../settings/settings_screen.dart';

import 'widgets/aurora_radio_section.dart';
import 'widgets/greeting.dart';
import 'widgets/home_header.dart';
import 'widgets/made_for_you.dart';
import 'widgets/mini_player.dart';
import 'widgets/new_releases.dart';
import 'widgets/recently_played.dart';
import 'widgets/top_artists.dart';
import 'widgets/trending_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();

  // Existing Home navigation remains unchanged.
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _onDestinationSelected(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SearchScreen()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LibraryScreen()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      extendBody: true,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              HomeHeader(),
              SizedBox(height: 28),
              GreetingSection(),
              SizedBox(height: 28),
              AuroraSearchBar(),
              SizedBox(height: 28),
              FeaturedBanner(),
              SizedBox(height: 36),
              MadeForYouSection(),
              SizedBox(height: 32),
              AuroraRadioSection(),
              SizedBox(height: 32),
              RecentlyPlayed(),
              SizedBox(height: 32),
              TrendingSection(),
              SizedBox(height: 32),
              NewReleases(),
              SizedBox(height: 32),
              TopArtistsSection(),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomSheet: const MiniPlayer(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        height: 72,
        backgroundColor: const Color(0xFF18181B),
        indicatorColor: const Color(0xFFA855F7),
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_music_outlined),
            selectedIcon: Icon(Icons.library_music),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
