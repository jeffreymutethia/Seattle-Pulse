import 'package:flutter/foundation.dart';
import 'package:seattle_pulse_mobile/src/core/api/api_client.dart';

class CommentRepository {
  final ApiClient _apiClient = ApiClient();

  // Add a new comment or reply
  Future<Map<String, dynamic>> postComment({
    required int contentId,
    required String content,
    String contentType = 'user_content',
    int? parentId,
  }) async {
    try {
      debugPrint(
          'Posting comment with data: contentId=$contentId, content=$content, contentType=$contentType, parentId=$parentId');

      final data = {
        'content_id': contentId.toString(),
        'content_type': contentType,
        'content': content,
      };

      if (parentId != null) {
        data['parent_id'] = parentId.toString();
      }

      final response = await _apiClient.post(
        '/comments/post_comment',
        data: data,
      );

      debugPrint('Comment API response status code: ${response.statusCode}');
      debugPrint('Comment API response data: ${response.data}');

      return response.data;
    } catch (e) {
      debugPrint('Error posting comment: $e');
      throw Exception('Failed to post comment: $e');
    }
  }

  // Update an existing comment
  Future<Map<String, dynamic>> updateComment({
    required int commentId,
    required String content,
  }) async {
    try {
      debugPrint('Updating comment: commentId=$commentId, content=$content');

      final response = await _apiClient.put(
        '/comments/update_comment',
        data: {
          'comment_id': commentId,
          'content': content,
        },
      );

      debugPrint(
          'Update comment API response status code: ${response.statusCode}');
      debugPrint('Update comment API response data: ${response.data}');

      return response.data;
    } catch (e) {
      debugPrint('Error updating comment: $e');
      throw Exception('Failed to update comment: $e');
    }
  }

  // Get replies for a specific comment
  Future<Map<String, dynamic>> getCommentReplies({
    required int commentId,
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      debugPrint(
          'Fetching replies for comment: commentId=$commentId, page=$page, perPage=$perPage');

      final response = await _apiClient.get(
        '/comments/$commentId/replies',
        queryParams: {
          'page': page.toString(),
          'per_page': perPage.toString(),
        },
      );

      debugPrint(
          'Get replies API response status code: ${response.statusCode}');
      debugPrint('Get replies API response data: ${response.data}');

      return response.data;
    } catch (e) {
      debugPrint('Error getting comment replies: $e');
      throw Exception('Failed to get comment replies: $e');
    }
  }

  // Get content details including comments
  Future<Map<String, dynamic>> getContentDetails({
    required int contentId,
    required String contentType,
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      debugPrint(
          'Fetching content details: contentId=$contentId, contentType=$contentType, page=$page, perPage=$perPage');

      final response = await _apiClient.get(
        '/content/$contentType/$contentId',
        queryParams: {
          'page': page.toString(),
          'per_page': perPage.toString(),
        },
      );

      debugPrint(
          'Get content details API response status code: ${response.statusCode}');
      debugPrint('Get content details API response data: ${response.data}');

      return response.data;
    } catch (e) {
      debugPrint('Error getting content details: $e');
      throw Exception('Failed to get content details: $e');
    }
  }
}
