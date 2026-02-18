import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seattle_pulse_mobile/src/core/api/api_client.dart';
import 'package:seattle_pulse_mobile/src/features/feed/data/service/content_detail_service.dart';
import 'package:seattle_pulse_mobile/src/features/feed/providers/content_details_notifier.dart';
import 'package:seattle_pulse_mobile/src/features/feed/providers/content_details_state.dart';


final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(); // Ensure your API client is properly configured
});

final contentDetailsServiceProvider = Provider<ContentDetailsService>((ref) {
  final client = ref.watch(apiClientProvider);
  return ContentDetailsService(client);
});

// Use StateNotifierProvider.family to pass parameters (contentType & contentId)
final contentDetailsNotifierProvider = StateNotifierProvider.family<ContentDetailsNotifier, ContentDetailsState, Map<String, dynamic>>(
  (ref, params) {
    final service = ref.watch(contentDetailsServiceProvider);
    final contentType = params['contentType'] as String;
    final contentId = params['contentId'] as int;
    return ContentDetailsNotifier(
      service,
      contentType: contentType,
      contentId: contentId,
    );
  },
);
