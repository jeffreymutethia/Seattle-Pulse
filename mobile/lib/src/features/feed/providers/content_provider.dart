import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seattle_pulse_mobile/src/core/api/api_client.dart';
import 'package:seattle_pulse_mobile/src/features/feed/data/service/content_service.dart';
import 'package:seattle_pulse_mobile/src/features/feed/providers/content_notifier.dart';
import 'package:seattle_pulse_mobile/src/features/feed/providers/content_state.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(); // Make sure this is configured properly to point to your server
});

final contentServiceProvider = Provider<ContentService>((ref) {
  final client = ref.watch(apiClientProvider);
  return ContentService(client);
});

final contentNotifierProvider =
    StateNotifierProvider<ContentNotifier, ContentState>((ref) {
  final contentService = ref.watch(contentServiceProvider);
  return ContentNotifier(contentService);
});
