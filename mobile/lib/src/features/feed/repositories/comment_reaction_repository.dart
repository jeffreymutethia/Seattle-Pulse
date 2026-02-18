import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:seattle_pulse_mobile/src/core/api/api_client.dart';
import 'package:seattle_pulse_mobile/src/core/widgets/reaction_popup.dart';

class CommentReactionRepository {
  final ApiClient _apiClient;

  CommentReactionRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// React to a comment
  Future<Map<String, dynamic>> reactToComment({
    required int commentId,
    required String reactionType,
  }) async {
    try {
      debugPrint(
          "REPOSITORY: Reacting to comment $commentId with reaction: $reactionType");

      final response = await _apiClient.post(
        '/comments/react/$commentId',
        data: {'reaction_type': reactionType.toUpperCase()},
      );

      debugPrint(
          "REPOSITORY: Comment reaction API Response status: ${response.statusCode}");

      // Log full response to help with debugging
      final responseData = response.data;
      debugPrint(
          "REPOSITORY: Comment reaction API Response data: $responseData");

      // Normalize response format
      if (responseData['success'] == 'success' &&
          responseData['status'] == null) {
        responseData['status'] = 'success';
      }

      return responseData;
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Failed to react to comment: $e');
    }
  }

  /// Convert Reaction model to API reaction type string
  String mapReactionToApiType(Reaction reaction) {
    // Map our reaction types to the API's accepted values
    switch (reaction.name.toLowerCase()) {
      case 'like':
        return 'LIKE';
      case 'love':
        return 'HEART';
      case 'haha':
        return 'HAHA';
      case 'wow':
        return 'WOW';
      case 'sad':
        return 'SAD';
      case 'angry':
        return 'ANGRY';
      default:
        return 'LIKE';
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
