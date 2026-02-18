// lib/src/features/users/providers/user_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/search_model.dart';
import '../repositories/search_repository.dart';

final userSearchProvider =
    StateNotifierProvider<UserSearchNotifier, List<UserModel>>((ref) {
  return UserSearchNotifier();
});

class UserSearchNotifier extends StateNotifier<List<UserModel>> {
  UserSearchNotifier() : super([]);

  final _userService = SearchRepository();

  Future<void> search(String query) async {
    try {
      final users = await _userService.searchUsers(query);
      state = users;
    } catch (e) {
      state = []; // Clear state on error
      rethrow;
    }
  }
}
