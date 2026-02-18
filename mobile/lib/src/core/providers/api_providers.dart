import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seattle_pulse_mobile/src/core/api/api_client.dart';

// Define the ApiClient provider
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});
