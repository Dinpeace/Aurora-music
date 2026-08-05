import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/music_repository.dart';

final musicRepositoryProvider = Provider<MusicRepository>(
  (ref) => const MusicRepository(),
);