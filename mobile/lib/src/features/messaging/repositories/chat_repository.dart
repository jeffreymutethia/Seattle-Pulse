import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../models/chat.dart';
import '../models/message.dart';

class ChatRepository {
  final ApiClient _apiClient;

  ChatRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  // Fetch all chats (direct and group)
  Future<List<dynamic>> getAllChats({int page = 1, int limit = 20}) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.allChats,
        queryParams: {'page': page, 'limit': limit},
      );

      if (response.statusCode == 200) {
        final data = response.data['data']['chats'] as List<dynamic>;
        return data;
      } else {
        throw Exception('Failed to fetch chats: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching all chats: $e');
      rethrow;
    }
  }

  // Start a direct chat with another user
  Future<Map<String, dynamic>> startDirectChat(String userId) async {
    try {
      // Based on the API documentation format: http://localhost:5001/v1/chat/direct/start/3
      debugPrint('Starting direct chat with user ID: $userId');

      // Update the endpoint to use the correct format
      final endpoint = '${ApiEndpoints.directChatStart}/$userId';
      debugPrint('Using endpoint: $endpoint');

      final response = await _apiClient.post(endpoint);

      debugPrint('Start chat response status: ${response.statusCode}');
      debugPrint('Start chat response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data == null) {
          // Handle empty response case
          debugPrint('Empty response data from start chat API');
          // Create a minimal valid response with the user ID
          return {
            'chat_id': 'chat_${DateTime.now().millisecondsSinceEpoch}',
            'receiver_id': userId,
          };
        }

        // If the API returns data in the expected format
        if (response.data is Map && response.data['data'] != null) {
          return response.data['data'] as Map<String, dynamic>;
        } else {
          // Create a valid response from the raw response
          return {
            'chat_id': 'chat_${DateTime.now().millisecondsSinceEpoch}',
            'receiver_id': userId,
            'raw_response': response.data,
          };
        }
      } else {
        throw Exception('Failed to start chat: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error starting direct chat: $e');
      rethrow;
    }
  }

  // Get messages for a chat with pagination
  Future<Map<String, dynamic>> getDirectChatMessages(String chatId,
      {int page = 1, int limit = 20}) async {
    try {
      debugPrint(
          'Fetching messages for chat $chatId (page=$page, limit=$limit)');

      final response = await _apiClient.get(
        '${ApiEndpoints.directChatMessages}/$chatId/messages',
        queryParams: {'page': page, 'limit': limit},
      );

      debugPrint('Got response: status=${response.statusCode}');

      if (response.statusCode == 200) {
        // Based on API documentation, response format is:
        // { status, message, data: { chat_id, messages: [...], pagination: {...}, receiver: {...} } }
        final responseData = response.data;

        if (responseData['status'] == 'success' &&
            responseData['data'] != null) {
          final data = responseData['data'] as Map<String, dynamic>;

          // Log the receiver details from API
          if (data['receiver'] != null) {
            final receiver = data['receiver'] as Map<String, dynamic>;
            debugPrint(
                'Receiver from API: id=${receiver['id']}, name=${receiver['first_name']} ${receiver['last_name']}');
          }

          // Return the data structure as is from the API
          return data;
        } else {
          throw Exception(responseData['message'] ?? 'Failed to get messages');
        }
      } else {
        throw Exception('Failed to get messages: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting direct chat messages: $e');
      // Return an empty structure for fallback
      return {
        'chat_id': chatId,
        'messages': [],
        'pagination': {'current_page': 1, 'total_pages': 1}
      };
    }
  }

  // Send a direct message
  Future<Map<String, dynamic>> sendDirectMessage(
      String chatId, String content) async {
    try {
      // According to the API documentation, we need to send chat_id and content
      final response = await _apiClient.post(
        ApiEndpoints.directChatSend,
        data: {
          'chat_id': chatId,
          'content': content,
        },
      );

      if (response.statusCode == 201) {
        // Based on API docs, response should have status, message, and data fields
        final responseData = response.data;

        if (responseData['status'] == 'success') {
          // Return the message data object from the API response
          return responseData['data'] as Map<String, dynamic>;
        } else {
          throw Exception(responseData['message'] ?? 'Failed to send message');
        }
      } else {
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error sending direct message: $e');
      rethrow;
    }
  }

  // Delete a message
  Future<bool> deleteMessage(String messageId,
      {bool deleteForAll = true}) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.directMessageDelete,
        data: {
          'message_id': messageId,
          'delete_for_all': deleteForAll,
        },
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        return responseData['status'] == 'success';
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting message: $e');
      return false; // Return false instead of rethrowing to prevent app crashes
    }
  }

  // Delete an entire chat
  Future<bool> deleteChat(String chatId) async {
    try {
      final response = await _apiClient.post(
        '${ApiEndpoints.directChatDelete}/$chatId',
        data: {'_method': 'DELETE'},
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        return responseData['status'] == 'success';
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting chat: $e');
      rethrow;
    }
  }

  // Edit a message
  Future<Map<String, dynamic>> editMessage(
      String messageId, String newContent) async {
    try {
      final response = await _apiClient.put(
        '${ApiEndpoints.directMessageEdit}/$messageId',
        data: {'content': newContent},
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['status'] == 'success' &&
            responseData['result'] != null) {
          return responseData['result']['message_data'] as Map<String, dynamic>;
        } else {
          throw Exception(responseData['message'] ?? 'Failed to edit message');
        }
      } else {
        throw Exception('Failed to edit message: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error editing message: $e');
      rethrow;
    }
  }
}
