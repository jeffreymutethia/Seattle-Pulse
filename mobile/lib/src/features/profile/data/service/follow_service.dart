import 'package:flutter/foundation.dart';
import 'package:seattle_pulse_mobile/src/core/api/api_client.dart';
import 'package:seattle_pulse_mobile/src/features/profile/data/models/follower_model.dart';

class FollowService {
  final ApiClient api;

  FollowService(this.api);

  // Follow a user
  Future<Map<String, dynamic>> followUser(int userId) async {
    debugPrint("FollowService: Following user with ID $userId");
    try {
      final response = await api.post('/follow/$userId');
      debugPrint("FollowService: Follow response => ${response.data}");
      return response.data;
    } catch (e) {
      debugPrint("FollowService: Error following user => $e");
      rethrow;
    }
  }

  // Unfollow a user
  Future<Map<String, dynamic>> unfollowUser(int userId) async {
    debugPrint("FollowService: Unfollowing user with ID $userId");
    try {
      final response = await api.post('/unfollow/$userId');
      debugPrint("FollowService: Unfollow response => ${response.data}");
      return response.data;
    } catch (e) {
      debugPrint("FollowService: Error unfollowing user => $e");
      rethrow;
    }
  }

  // Get followers list
  Future<FollowersResponse> getFollowers({String? query}) async {
    debugPrint("FollowService: Getting followers list");
    try {
      final response = await api.get(
        '/get_followers',
        queryParams: query != null ? {'query': query} : null,
      );
      debugPrint("FollowService: Followers response => ${response.data}");
      return FollowersResponse.fromJson(response.data);
    } catch (e) {
      debugPrint("FollowService: Error getting followers => $e");
      rethrow;
    }
  }

  // Get following list
  Future<FollowersResponse> getFollowing({String? query}) async {
    debugPrint("FollowService: Getting following list");
    try {
      final response = await api.get(
        '/get_following',
        queryParams: query != null ? {'query': query} : null,
      );
      debugPrint("FollowService: Following response => ${response.data}");
      return FollowersResponse.fromJson(response.data);
    } catch (e) {
      debugPrint("FollowService: Error getting following => $e");
      rethrow;
    }
  }
}
