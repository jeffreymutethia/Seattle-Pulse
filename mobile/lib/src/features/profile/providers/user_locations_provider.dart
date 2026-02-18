// user_locations_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seattle_pulse_mobile/src/features/profile/data/service/profile_service.dart';
import 'user_locations_notifier.dart';
import 'package:seattle_pulse_mobile/src/core/api/api_client.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final userLocationsServiceProvider = Provider<UserLocationsService>((ref) {
  return UserLocationsService(ref.watch(apiClientProvider));
});

final userLocationsNotifierProvider = StateNotifierProvider.family<
    UserLocationsNotifier, UserLocationsState, String>(
  (ref, username) {
    final service = ref.watch(userLocationsServiceProvider);
    return UserLocationsNotifier(service, username: username);
  },
);
