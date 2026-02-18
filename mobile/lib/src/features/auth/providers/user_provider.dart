import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seattle_pulse_mobile/src/features/auth/data/service/user_secure_storage.dart';

// FutureProvider to load current user ID from secure storage
final currentUserIdProvider = FutureProvider<int?>((ref) async {
  final user = await SecureStorageService.getUser(); // Your async storage call
  return user?.userId;
});
