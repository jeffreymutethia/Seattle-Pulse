import 'package:dio/dio.dart';
import 'package:seattle_pulse_mobile/src/core/api/api_client.dart';
import 'package:seattle_pulse_mobile/src/core/widgets/reaction_popup.dart';

class ReactionRepository {
  final ApiClient _apiClient;

  ReactionRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// React to user content (posts, articles, etc.)
  Future<Map<String, dynamic>> reactToContent({
    required int contentId,
    required String reactionType,
  }) async {
    try {
      final response = await _apiClient.post(
        '/reaction/user_content/$contentId',
        data: {'reaction_type': reactionType.toUpperCase()},
      );

      return response.data;
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Failed to react to content: $e');
    }
  }

  /// React to comments
  Future<Map<String, dynamic>> reactToComment({
    required int contentId,
    required int commentId,
    required String reactionType,
  }) async {
    try {
      final response = await _apiClient.post(
        '/reaction/comment/$contentId/$commentId',
        data: {'reaction_type': reactionType.toUpperCase()},
      );

      return response.data;
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
