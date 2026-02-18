import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seattle_pulse_mobile/src/features/auth/data/models/user_model.dart';
import 'package:seattle_pulse_mobile/src/features/auth/data/service/user_secure_storage.dart';

final storedUserProvider = FutureProvider<UserModel?>((ref) async {
  return await SecureStorageService.getUser();
});
