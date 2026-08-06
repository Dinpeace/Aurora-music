import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/music_repository.dart';
import '../../data/services/local_music_service.dart';

final localMusicServiceProvider = Provider<LocalMusicService>(
  (ref) => const LocalMusicService(),
);

final musicRepositoryProvider = Provider<MusicRepository>(
  (ref) => MusicRepository(
    localMusicService: ref.watch(localMusicServiceProvider),
  ),
);