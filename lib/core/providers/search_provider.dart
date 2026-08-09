import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/online/provider_client.dart';
import '../../data/repositories/online_repository.dart';
import '../../features/search/search_controller.dart';
import '../../features/search/search_state.dart';

final onlineRepositoryProvider =
    Provider(
  (_) => OnlineRepository(
    provider: ProviderClient(),
  ),
);

final searchControllerProvider =
    StateNotifierProvider<
        SearchController,
        SearchState>(
  (ref) => SearchController(
    ref.watch(onlineRepositoryProvider),
  ),
);