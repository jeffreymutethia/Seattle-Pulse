import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seattle_pulse_mobile/src/core/api/api_client.dart';
import 'package:seattle_pulse_mobile/src/features/feed/data/service/content_service.dart';
import 'package:seattle_pulse_mobile/src/features/feed/providers/content_notifier.dart';
import 'package:seattle_pulse_mobile/src/features/feed/providers/content_state.dart';
import 'package:seattle_pulse_mobile/src/features/mypulse/data/service/mypulse_service.dart';
import 'package:seattle_pulse_mobile/src/features/mypulse/providers/mypulse_notifier.dart';
import 'package:seattle_pulse_mobile/src/features/mypulse/providers/mypulse_state.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final myPulseServiceProvider = Provider<MypulseService>((ref) {
  final client = ref.watch(apiClientProvider);
  return MypulseService(client);
});

final myPulseNotifierProvider =
    StateNotifierProvider<MypulseNotifier, MyPulseState>((ref) {
  final myPulseService = ref.watch(myPulseServiceProvider);
  return MypulseNotifier(myPulseService);
});
