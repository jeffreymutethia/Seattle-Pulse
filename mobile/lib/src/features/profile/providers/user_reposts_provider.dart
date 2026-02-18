import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seattle_pulse_mobile/src/core/api/api_client.dart';
import 'package:seattle_pulse_mobile/src/features/profile/data/service/profile_service.dart';
import 'user_reposts_notifier.dart';


final apiClientProvider = Provider<ApiClient>((ref) {
  // Return your configured ApiClient instance here.
  return ApiClient();
});

final userRepostsServiceProvider = Provider<UserRepostsService>((ref) {
  return UserRepostsService(ref.watch(apiClientProvider));
});

final userRepostsNotifierProvider = StateNotifierProvider.family<UserRepostsNotifier, UserRepostsState, String>(
  (ref, username) {
    final service = ref.watch(userRepostsServiceProvider);
    return UserRepostsNotifier(service, username: username);
  },
);
