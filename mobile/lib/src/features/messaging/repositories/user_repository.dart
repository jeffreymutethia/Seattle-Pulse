import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../models/chat_user.dart';

class UserRepository {
  final ApiClient _apiClient;

  UserRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  // Search users from the following list
  Future<List<ChatUser>> searchUsers(String query) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.getFollowing,
        queryParams: query.isNotEmpty ? {'query': query} : null,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['status'] == 'success' &&
            responseData['users'] != null) {
          final usersData = responseData['users'] as List<dynamic>;
          return usersData
              .map((userData) =>
                  ChatUser.fromApi(userData as Map<String, dynamic>))
              .toList();
        } else {
          return [];
        }
      } else {
        debugPrint('Failed to search users: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error searching users: $e');
      return [];
    }
  }

  // Get followers list
  Future<List<ChatUser>> getFollowers() async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.getFollowers,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['status'] == 'success' &&
            responseData['users'] != null) {
          final usersData = responseData['users'] as List<dynamic>;
          return usersData
              .map((userData) =>
                  ChatUser.fromApi(userData as Map<String, dynamic>))
              .toList();
        } else {
          return [];
        }
      } else {
        debugPrint('Failed to get followers: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error getting followers: $e');
      return [];
    }
  }
}
