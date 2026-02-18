

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seattle_pulse_mobile/src/core/api/api_client.dart';
import 'package:seattle_pulse_mobile/src/features/profile/data/service/profile_service.dart';
import 'package:seattle_pulse_mobile/src/features/profile/providers/user_profile_notifier.dart';


final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(); // Make sure this is configured properly to point to your server
});

final userProfileServiceProvider = Provider<UserProfileService>((ref) {
  return UserProfileService(ref.watch(apiClientProvider));
});

final userProfileNotifierProvider = StateNotifierProvider.family<UserProfileNotifier, UserProfileState, String>(
  (ref, username) {
    final service = ref.watch(userProfileServiceProvider);
    return UserProfileNotifier(service, username: username);
  },
);