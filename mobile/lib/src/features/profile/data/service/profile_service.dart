import 'package:flutter/foundation.dart';
import 'package:seattle_pulse_mobile/src/core/api/api_client.dart';
import 'package:seattle_pulse_mobile/src/features/profile/data/models/user_profile_model.dart';
import 'package:seattle_pulse_mobile/src/features/profile/data/models/user_locations_model.dart';
import 'package:seattle_pulse_mobile/src/features/profile/data/models/user_posts_model.dart';
import 'package:seattle_pulse_mobile/src/features/profile/data/models/user_reposts_model.dart';


class UserProfileService {
  final ApiClient api;

  UserProfileService(this.api);

  Future<UserProfileResponse> fetchUserProfile(String username) async {
    debugPrint("UserProfileService: Requesting /profile/$username ...");
    final response = await api.get('/profile/$username');
    debugPrint("UserProfileService: Response => ${response.data.toString().substring(0, 100)}...");
    return UserProfileResponse.fromJson(response.data);
  }
}



class UserPostsService {
  final ApiClient api;

  UserPostsService(this.api);

  Future<UserPostsResponse> fetchUserPosts(String username,
      {int page = 1, int perPage = 10}) async {
    debugPrint("UserPostsService: Requesting /profile/$username/posts?page=$page&per_page=$perPage ...");
    final response = await api.get('/profile/$username/posts?page=$page&per_page=$perPage');
    debugPrint("UserPostsService: Response => ${response.data.toString().substring(0, 100)}...");
    return UserPostsResponse.fromJson(response.data);
  }
}




class UserRepostsService {
  final ApiClient api;

  UserRepostsService(this.api);

  Future<UserRepostsResponse> fetchUserReposts(String username,
      {int page = 1, int perPage = 10}) async {
    debugPrint("UserRepostsService: Requesting /profile/$username/reposts?page=$page&per_page=$perPage ...");
    final response = await api.get('/profile/$username/reposts?page=$page&per_page=$perPage');
    debugPrint("UserRepostsService: Response => ${response.data.toString().substring(0, 100)}...");
    return UserRepostsResponse.fromJson(response.data);
  }
}




class UserLocationsService {
  final ApiClient api;

  UserLocationsService(this.api);

  Future<UserLocationsResponse> fetchUserLocations(String username,
      {int page = 1, int perPage = 10}) async {
    debugPrint("UserLocationsService: Requesting /content/user/$username/locations?page=$page&per_page=$perPage ...");
    final response = await api.get('/content/user/$username/locations?page=$page&per_page=$perPage');
    debugPrint("UserLocationsService: Response => ${response.data.toString().substring(0, 100)}...");
    return UserLocationsResponse.fromJson(response.data);
  }
}

