// add_story_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seattle_pulse_mobile/src/core/api/api_client.dart';
import 'package:seattle_pulse_mobile/src/features/add-story/data/story_service.dart';
import 'package:seattle_pulse_mobile/src/features/add-story/data/aws_upload_service.dart';
import 'package:seattle_pulse_mobile/src/features/add-story/data/location_service.dart';
import 'package:seattle_pulse_mobile/src/features/add-story/providers/add_story_notifier.dart';
import 'package:seattle_pulse_mobile/src/features/add-story/providers/location_notifier.dart';

// Provider for the API client
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

// Provider for the AWS upload service
final awsUploadServiceProvider = Provider<AwsUploadService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AwsUploadService(apiClient);
});

// Provider for the location service
final locationServiceProvider = Provider<LocationService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return LocationService(apiClient);
});

// Provider for the story repository
final storyRepositoryProvider = Provider<StoryRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return StoryRepository(apiClient);
});

// Provider for the add story notifier
final addStoryNotifierProvider =
    StateNotifierProvider<AddStoryNotifier, AddStoryState>((ref) {
  final storyRepo = ref.watch(storyRepositoryProvider);
  return AddStoryNotifier(storyRepo);
});

// Provider for location search state
final locationSearchProvider =
    StateNotifierProvider<LocationSearchNotifier, LocationSearchState>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  return LocationSearchNotifier(locationService);
});
