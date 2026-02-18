// lib/src/features/users/repositories/user_repository.dart

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:seattle_pulse_mobile/src/core/api/api_client.dart';
import '../models/search_model.dart';

class SearchRepository {
  final ApiClient _apiClient;

  SearchRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Search users by username
  Future<List<UserModel>> searchUsers(String query, {bool save = true}) async {
    try {
      debugPrint("REPOSITORY: Searching for users with query: $query");

      final response = await _apiClient.get(
        '/users/search',
        queryParams: {
          'query': query,
          'save': save.toString(),
        },
      );

      debugPrint("REPOSITORY: Search API status: ${response.statusCode}");

      final data = response.data['data'] as List;
      return data.map((json) => UserModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }

  Exception _handleDioException(DioException e) {
    if (e.response != null) {
      final responseData = e.response!.data;
      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('message')) {
        return Exception(responseData['message']);
      }
      return Exception('API Error: ${e.response!.statusCode}');
    }
    return Exception('Network error: ${e.message}');
  }
}
