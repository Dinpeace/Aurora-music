import 'package:go_router/go_router.dart';

import '../../features/home/home_screen.dart';
import '../../features/player/player_screen.dart';
import '../../features/search/search_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) {
        return const HomeScreen();
      },
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) {
        return const SearchScreen();
      },
    ),
    GoRoute(
      path: '/player',
      builder: (context, state) {
        return const PlayerScreen();
      },
    ),
  ],
);
