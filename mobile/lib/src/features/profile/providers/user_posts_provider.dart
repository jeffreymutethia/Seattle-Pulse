// user_posts_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seattle_pulse_mobile/src/features/profile/data/service/profile_service.dart';
import 'user_posts_notifier.dart';
import 'package:seattle_pulse_mobile/src/core/api/api_client.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final userPostsServiceProvider = Provider<UserPostsService>((ref) {
  return UserPostsService(ref.watch(apiClientProvider));
});

final userPostsNotifierProvider = StateNotifierProvider.family<UserPostsNotifier, UserPostsState, String>(
  (ref, username) {
    final service = ref.watch(userPostsServiceProvider);
    return UserPostsNotifier(service, username: username);
  },
);
