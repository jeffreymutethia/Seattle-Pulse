import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../models/chat_user.dart';
import '../repositories/user_repository.dart';

// Provider for UserRepository
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

// Provider for search query
final searchQueryProvider = StateProvider<String>((ref) {
  return '';
});

// Provider for search loading state
final searchLoadingProvider = StateProvider<bool>((ref) {
  return false;
});

// Provider for search results
final userSearchResultsProvider =
    StateNotifierProvider<UserSearchNotifier, List<ChatUser>>((ref) {
  final userRepository = ref.watch(userRepositoryProvider);
  return UserSearchNotifier(userRepository);
});

class UserSearchNotifier extends StateNotifier<List<ChatUser>> {
  final UserRepository _userRepository;

  UserSearchNotifier(this._userRepository) : super([]);

  // Search users with the given query
  Future<void> searchUsers(String query,
      {required StateController<bool> loadingController}) async {
    try {
      // Set loading state
      loadingController.state = true;

      // Get search results
      final results = await _userRepository.searchUsers(query);

      // Update state with results
      state = results;
    } catch (e) {
      debugPrint('Error in user search: $e');
      state = [];
    } finally {
      // Clear loading state
      loadingController.state = false;
    }
  }

  // Get followers list
  Future<void> getFollowers(
      {required StateController<bool> loadingController}) async {
    try {
      // Set loading state
      loadingController.state = true;

      // Get followers
      final followers = await _userRepository.getFollowers();

      // Update state with followers
      state = followers;
    } catch (e) {
      debugPrint('Error getting followers: $e');
      state = [];
    } finally {
      // Clear loading state
      loadingController.state = false;
    }
  }
}

// Provider for selected users (for adding to group)
final selectedUsersProvider =
    StateNotifierProvider<SelectedUsersNotifier, List<ChatUser>>((ref) {
  return SelectedUsersNotifier();
});

class SelectedUsersNotifier extends StateNotifier<List<ChatUser>> {
  SelectedUsersNotifier() : super([]);

  // Toggle selection of a user
  void toggleUser(ChatUser user) {
    if (isSelected(user.id)) {
      state =
          state.where((selectedUser) => selectedUser.id != user.id).toList();
    } else {
      state = [...state, user];
    }
  }

  // Check if a user is selected
  bool isSelected(String userId) {
    return state.any((user) => user.id == userId);
  }

  // Clear all selections
  void clearAll() {
    state = [];
  }

  // Get the count of selected users
  int get count => state.length;
}

// States for user search
enum UserFetchState { initial, loading, success, error }

// Provider for user search state
final userFetchStateProvider = StateProvider<UserFetchState>((ref) {
  return UserFetchState.initial;
});

// Provider for user search error
final userFetchErrorProvider = StateProvider<String?>((ref) {
  return null;
});

// Provider for the list of users from get_following API
final followingUsersProvider =
    StateNotifierProvider<FollowingUsersNotifier, List<ChatUser>>((ref) {
  return FollowingUsersNotifier(ApiClient());
});

// Provider for filtered/search results
final filteredUsersProvider = Provider<List<ChatUser>>((ref) {
  final users = ref.watch(followingUsersProvider);
  final searchQuery = ref.watch(userSearchQueryProvider);

  if (searchQuery.isEmpty) {
    return users;
  }

  return users.where((user) {
    final name = user.name.toLowerCase();
    final username = user.username?.toLowerCase() ?? '';
    final query = searchQuery.toLowerCase();

    return name.contains(query) || username.contains(query);
  }).toList();
});

// Provider for search query
final userSearchQueryProvider = StateProvider<String>((ref) => '');

// Notifier for following users
class FollowingUsersNotifier extends StateNotifier<List<ChatUser>> {
  final ApiClient _apiClient;

  FollowingUsersNotifier(this._apiClient) : super([]) {
    // Load users on initialization
    fetchFollowingUsers();
  }

  Future<void> fetchFollowingUsers({String? searchQuery}) async {
    try {
      final Map<String, dynamic>? queryParams =
          searchQuery != null && searchQuery.isNotEmpty
              ? {'query': searchQuery}
              : null;

      final response = await _apiClient.get(
        ApiEndpoints.getFollowing,
        queryParams: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data;

        if (responseData['status'] == 'success' &&
            responseData['users'] != null) {
          final usersData = responseData['users'] as List<dynamic>;

          final users = usersData.map((userData) {
            return ChatUser.fromApi(userData as Map<String, dynamic>);
          }).toList();

          state = users;
          return;
        }
      }

      // If we get here, there was an issue with the response format
      debugPrint(
          'Invalid response format from getFollowing API: ${response.data}');
    } catch (e) {
      debugPrint('Error fetching following users: $e');
      // Don't update state, keep existing data
    }
  }

  // Search following users with API
  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      fetchFollowingUsers();
      return;
    }

    return fetchFollowingUsers(searchQuery: query);
  }
}

// Provider for suggested users (can be used in new message screen)
final suggestedUsersProvider = Provider<List<ChatUser>>((ref) {
  return ref.watch(followingUsersProvider);
});
