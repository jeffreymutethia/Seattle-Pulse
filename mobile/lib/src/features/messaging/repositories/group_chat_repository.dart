import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../models/chat.dart';
import '../models/chat_user.dart';
import '../models/message.dart';
import '../repositories/chat_repository.dart';

class GroupChatRepository {
  final ApiClient _apiClient;

  GroupChatRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  // Create a new group chat
  Future<Chat> createGroupChat(String name) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.groupCreate,
        data: {
          'name': name,
        },
      );

      if (response.statusCode == 201) {
        final responseData = response.data;
        if (responseData['status'] == 'success' &&
            responseData['data'] != null) {
          final groupData =
              responseData['data']['group'] as Map<String, dynamic>;
          return Chat.fromGroupApi(groupData);
        } else {
          throw Exception(responseData['message'] ?? 'Failed to create group');
        }
      } else {
        throw Exception('Failed to create group: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error creating group chat: $e');
      rethrow;
    }
  }

  // Send a message to a group chat
  Future<Message> sendGroupMessage(String groupId, String content) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.groupSendMessage,
        data: {
          'group_chat_id': groupId,
          'content': content,
        },
      );

      if (response.statusCode == 201) {
        final responseData = response.data;
        if (responseData['status'] == 'success' &&
            responseData['data'] != null) {
          final messageData =
              responseData['data']['message'] as Map<String, dynamic>;
          return Message.fromApi(messageData);
        } else {
          throw Exception(responseData['message'] ?? 'Failed to send message');
        }
      } else {
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error sending group message: $e');
      rethrow;
    }
  }

  // Get messages for a group chat with pagination
  Future<Map<String, dynamic>> getGroupMessages(String groupId,
      {int page = 1, int limit = 20}) async {
    try {
      final response = await _apiClient.get(
        '${ApiEndpoints.groupMessages}/$groupId',
        queryParams: {'page': page, 'limit': limit},
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['status'] == 'success' &&
            responseData['data'] != null) {
          // Prepare standardized response format similar to direct messages
          final data = responseData['data'] as Map<String, dynamic>;

          // Standardize message format
          return {
            'total_messages': data['total_messages'] ?? 0,
            'total_pages': data['total_pages'] ?? 1,
            'current_page': data['current_page'] ?? 1,
            'messages': data['messages'] ?? [],
            'group_chat_id': groupId
          };
        } else {
          throw Exception(
              responseData['message'] ?? 'Failed to get group messages');
        }
      } else {
        throw Exception('Failed to get group messages: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting group messages: $e');
      return {
        'total_messages': 0,
        'total_pages': 1,
        'current_page': 1,
        'messages': [],
        'group_chat_id': groupId
      };
    }
  }

  // Get list of user's groups
  Future<List<Chat>> getUserGroups({int page = 1, int limit = 10}) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.groupList,
        queryParams: {'page': page, 'limit': limit},
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['status'] == 'success' &&
            responseData['data'] != null) {
          final groupsData = responseData['data']['groups'] as List<dynamic>;

          return groupsData.map((group) {
            final groupData = group as Map<String, dynamic>;

            // Extract the last message if messages array exists and has items
            Message? lastMessage;
            ChatUser? lastMessageSender;

            if (groupData['messages'] != null &&
                groupData['messages'] is List &&
                (groupData['messages'] as List).isNotEmpty) {
              final messagesData = groupData['messages'] as List;
              if (messagesData.isNotEmpty) {
                // Get the last message (which should be the most recent)
                final lastMessageData =
                    messagesData.last as Map<String, dynamic>;
                lastMessage = Message.fromApi(lastMessageData);

                // Extract sender info if available
                if (lastMessageData['sender'] != null) {
                  lastMessageSender = ChatUser.fromApi(
                      lastMessageData['sender'] as Map<String, dynamic>);
                  // Update the message with sender info
                  lastMessage = lastMessage.copyWith(sender: lastMessageSender);
                }
              }
            }

            // Create a list of ChatUsers from the members field if present
            List<ChatUser> participants = [];
            if (groupData['members'] != null && groupData['members'] is List) {
              final membersData = groupData['members'] as List;
              // For each member, we'd need their user information
              // Since the API response only contains member IDs and roles,
              // we can't fully populate the participants list here
            }

            // Create and return the Chat object with the group information
            return Chat(
              id: groupData['id'].toString(),
              name: groupData['name'] as String? ?? 'Group Chat',
              participants: participants,
              lastMessage: lastMessage,
              type: ChatType.group,
              createdAt: groupData['created_at'] != null
                  ? DateTime.parse(groupData['created_at'])
                  : DateTime.now(),
              createdBy: ChatUser(
                id: groupData['created_by'].toString(),
                name: 'Group Creator',
              ),
            );
          }).toList();
        } else {
          throw Exception(
              responseData['message'] ?? 'Failed to get user groups');
        }
      } else {
        throw Exception('Failed to get user groups: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting user groups: $e');
      return [];
    }
  }

  // Add a member to a group
  Future<bool> addMemberToGroup(String groupId, String userId) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.groupAddMember,
        data: {
          'group_chat_id': groupId,
          'user_id': userId,
        },
      );

      return response.statusCode == 201;
    } catch (e) {
      debugPrint('Error adding member to group: $e');
      rethrow;
    }
  }

  // Remove a member from a group
  Future<bool> removeMemberFromGroup(String groupId, String userId) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.groupRemoveMember,
        data: {
          'group_chat_id': groupId,
          'user_id': userId,
        },
        queryParams: {'_method': 'DELETE'},
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error removing member from group: $e');
      rethrow;
    }
  }

  // Join a group chat
  Future<bool> joinGroupChat(String groupChatId) async {
    try {
      debugPrint('===== JOINING GROUP CHAT =====');
      debugPrint('Group chat ID: $groupChatId');

      final response = await _apiClient.post(
        '/group/join',
        data: {
          'group_chat_id': groupChatId,
        },
      );

      debugPrint(
          'Join group response: ${response.statusCode}, ${response.data}');

      final success = response.statusCode == 200 || response.statusCode == 201;

      if (success) {
        debugPrint('✅ Successfully joined group chat');
      } else {
        debugPrint('❌ Failed to join group chat: ${response.data}');
      }

      return success;
    } catch (e) {
      debugPrint('❌ Error joining group chat: $e');
      return false;
    }
  }

  // Leave a group chat
  Future<Map<String, dynamic>> leaveGroupChat(String groupId,
      {bool deleteConfirmation = false}) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.groupLeave,
        data: {
          'group_chat_id': groupId,
          if (deleteConfirmation) 'delete_group_confirmation': true,
        },
      );

      // Extract the response data
      final responseData = response.data;

      // Handle 400 status code for delete confirmation
      if (response.statusCode == 400 &&
          responseData['status'] == 'error' &&
          responseData['data']?['delete_required'] == true) {
        return {
          'success': false,
          'message': responseData['message'],
          'delete_required': true,
        };
      }

      if (response.statusCode == 200) {
        if (responseData['status'] == 'success') {
          return {
            'success': true,
            'group_deleted': responseData['data']['group_deleted'] ?? false,
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'],
            'delete_required':
                responseData['data']?['delete_required'] ?? false,
          };
        }
      } else {
        throw Exception('Failed to leave group: ${response.statusCode}');
      }
    } catch (e) {
      // Handle DioException specifically to extract response data
      if (e is DioException && e.response != null) {
        final responseData = e.response!.data;
        if (e.response!.statusCode == 400 &&
            responseData['status'] == 'error' &&
            responseData['data']?['delete_required'] == true) {
          return {
            'success': false,
            'message': responseData['message'],
            'delete_required': true,
          };
        }
      }

      debugPrint('Error leaving group chat: $e');
      rethrow;
    }
  }

  // Assign or remove admin privileges
  Future<bool> assignAdminRole(
      String groupId, String userId, bool isAdmin) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.groupAssignAdmin,
        data: {
          'group_chat_id': groupId,
          'user_id': userId,
          'is_admin': isAdmin,
          '_method': 'PATCH',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error assigning admin role: $e');
      rethrow;
    }
  }

  // Delete a message in a group chat
  Future<bool> deleteGroupMessage(String messageId,
      {bool deleteForAll = true}) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.groupDeleteMessage,
        data: {'message_id': messageId, 'delete_for_all': deleteForAll},
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        return responseData['status'] == 'success';
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting group message: $e');
      return false;
    }
  }

  // Delete an entire group
  Future<bool> deleteGroup(String groupId) async {
    try {
      // First try using DELETE method as specified in the documentation
      try {
        final response = await _apiClient.delete(
          '/group/delete', // Use the exact path from documentation
          data: {
            'group_chat_id': groupId,
          },
        );

        if (response.statusCode == 200) {
          final responseData = response.data;
          return responseData['status'] == 'success';
        }
      } catch (e) {
        debugPrint('Error with DELETE method: $e');
        if (e is DioException && e.response?.statusCode == 405) {
          // If DELETE method fails with 405, try using POST method
          debugPrint('Falling back to POST method...');
        } else {
          rethrow; // If it's another error, just rethrow it
        }
      }

      // Try POST method as fallback
      final response = await _apiClient.post(
        '/group/delete',
        data: {
          'group_chat_id': groupId,
        },
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        return responseData['status'] == 'success';
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting group: $e');
      if (e is DioException && e.response != null) {
        debugPrint('Error response data: ${e.response!.data}');
      }
      rethrow;
    }
  }

  // Get all members of a group
  Future<List<ChatUser>> getGroupMembers(String groupId) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.groupMembers,
        queryParams: {'group_chat_id': groupId},
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['status'] == 'success' &&
            responseData['data'] != null) {
          final membersData = responseData['data']['members'] as List<dynamic>;
          return membersData
              .map((member) => ChatUser.fromApi(member as Map<String, dynamic>))
              .toList();
        } else {
          throw Exception(
              responseData['message'] ?? 'Failed to get group members');
        }
      } else {
        throw Exception('Failed to get group members: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting group members: $e');
      return [];
    }
  }

  // Get member count for a group
  Future<int> getGroupMemberCount(String groupId) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.groupMemberCount,
        queryParams: {'group_chat_id': groupId},
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['status'] == 'success' &&
            responseData['data'] != null) {
          return responseData['data']['count'] as int;
        } else {
          throw Exception(
              responseData['message'] ?? 'Failed to get member count');
        }
      } else {
        throw Exception('Failed to get member count: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting group member count: $e');
      return 0;
    }
  }

  // Edit a message in a group chat
  Future<Message> editGroupMessage(String messageId, String newContent) async {
    try {
      final response = await _apiClient.put(
        '${ApiEndpoints.groupEditMessage}/$messageId',
        data: {
          'content': newContent,
        },
      );

      final Map<String, dynamic> data = response.data;

      if (data['status'] != 'success' || data['result'] == null) {
        throw Exception('Failed to edit message: ${data['message']}');
      }

      return Message.fromApi(data['result']['message_data']);
    } catch (e) {
      debugPrint('Error editing group message: $e');
      throw Exception('Failed to edit message: $e');
    }
  }

  // Generate an invite link
  Future<String> generateInviteLink(String groupId) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.groupGenerateInvite,
        data: {
          'group_chat_id': groupId,
        },
      );

      final responseData = response.data;

      if (responseData['status'] == 'success' &&
          responseData['data'] != null &&
          responseData['data']['invite_link'] != null) {
        return responseData['data']['invite_link'] as String;
      } else {
        debugPrint('Unexpected response format: $responseData');
        throw Exception(
            responseData['message'] ?? 'Failed to generate invite link');
      }
    } catch (e) {
      debugPrint('Error generating invite link: $e');
      if (e is DioException && e.response != null) {
        debugPrint('Error response data: ${e.response!.data}');
      }
      throw Exception('Failed to generate invite link: $e');
    }
  }

  // Join group via invite link
  Future<bool> joinGroupViaInvite(String token) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.groupJoinInvite,
        queryParams: {'token': token},
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error joining group via invite: $e');
      rethrow;
    }
  }

  // Generate invite link for a group
  Future<String> generateGroupInviteLink(String groupId) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.groupGenerateInvite,
        data: {
          'group_chat_id': groupId,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        if (responseData['status'] == 'success' &&
            responseData['data'] != null) {
          // The API might return the token or a full URL
          final data = responseData['data'] as Map<String, dynamic>;

          if (data['invite_link'] != null) {
            return data['invite_link'] as String;
          } else if (data['token'] != null) {
            // Construct the invite link with the token
            final token = data['token'] as String;
            return '${ApiEndpoints.groupJoinInvite}?token=$token';
          }
        }

        throw Exception('Invalid invite link data from API');
      } else {
        throw Exception(
            'Failed to generate invite link: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error generating group invite link: $e');
      rethrow;
    }
  }

  // Join a group via invite link/token
  Future<Map<String, dynamic>> joinGroupViaInviteToken(String token) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.groupJoinInvite,
        data: {'token': token},
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['status'] == 'success' &&
            responseData['data'] != null) {
          return responseData['data'] as Map<String, dynamic>;
        } else {
          throw Exception(responseData['message'] ?? 'Failed to join group');
        }
      } else {
        throw Exception('Failed to join group: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error joining group via invite: $e');
      rethrow;
    }
  }

  // Send invite link via direct message
  Future<bool> sendGroupInviteToUser(String userId, String groupId,
      {String? message}) async {
    try {
      debugPrint('===== SENDING GROUP INVITE TO USER =====');
      debugPrint('userId: $userId, groupId: $groupId');

      // First generate an invite link
      final inviteLink = await generateGroupInviteLink(groupId);
      debugPrint('Generated invite link: $inviteLink');

      // Prepare the message content
      final content = message ?? 'Join our group chat! $inviteLink';
      debugPrint('Message content: $content');

      // We'll try multiple approaches to ensure this works
      bool success = false;

      // APPROACH 1: Try using the chat API with the chat_id
      try {
        // Start direct chat to get the chat ID
        final chatRepository = ChatRepository();
        debugPrint('Starting direct chat with user $userId...');
        final chatResponse = await chatRepository.startDirectChat(userId);
        debugPrint('Chat response: $chatResponse');

        // Extract the chat ID from the API response
        String? chatId;

        if (chatResponse.containsKey('chat') && chatResponse['chat'] is Map) {
          final chatData = chatResponse['chat'] as Map<String, dynamic>;
          chatId = chatData['id']?.toString();
          debugPrint('Found chat ID in chat data: $chatId');
        }

        // Fallback approach if we couldn't find the chat ID
        if (chatId == null) {
          debugPrint(
              'Chat ID not found in first try, attempting to extract from raw response');

          // Try to extract chat ID directly from the API response
          if (chatResponse is Map) {
            void searchMap(Map<dynamic, dynamic> map, String path) {
              map.forEach((key, value) {
                if (key == 'id' && chatId == null) {
                  chatId = value.toString();
                  debugPrint('Found potential chat ID at $path.id: $chatId');
                } else if (value is Map) {
                  searchMap(value, '$path.$key');
                }
              });
            }

            searchMap(chatResponse, 'root');
          }
        }

        // If we found a chat ID, send message to that chat
        if (chatId != null) {
          debugPrint('Sending message to chat ID: $chatId');
          final response = await _apiClient.post(
            ApiEndpoints.directChatSend,
            data: {
              'chat_id': chatId,
              'content': content,
            },
          );

          debugPrint(
              'Send message response: ${response.statusCode}, ${response.data}');

          if (response.statusCode == 200 || response.statusCode == 201) {
            debugPrint(
                '✅ Successfully sent invite message using chat_id approach');
            return true; // Success! We can exit early
          }
        }
      } catch (e) {
        debugPrint('⚠️ Error with chat_id approach: $e');
        // Continue to next approach
      }

      // APPROACH 2: Try direct message send approach with user_id
      try {
        debugPrint(
            'Trying to send direct message using user_id instead of chat_id...');
        final directResponse = await _apiClient.post(
          '/chat/direct/send',
          data: {
            'user_id': userId,
            'content': content,
          },
        );

        debugPrint(
            'Direct send response: ${directResponse.statusCode}, ${directResponse.data}');

        if (directResponse.statusCode == 200 ||
            directResponse.statusCode == 201) {
          debugPrint(
              '✅ Successfully sent invite message using user_id approach');
          return true; // Success!
        }
      } catch (e) {
        debugPrint('⚠️ Error with user_id approach: $e');
        // Continue to next approach
      }

      // APPROACH 3: Try the conversation endpoint with user_id
      try {
        debugPrint('Trying conversation endpoint approach...');

        // First create or get conversation with the user
        final conversationResponse = await _apiClient.post(
          '/chat/conversation',
          data: {
            'user_id': userId,
          },
        );

        debugPrint(
            'Conversation response: ${conversationResponse.statusCode}, ${conversationResponse.data}');

        if (conversationResponse.statusCode == 200 ||
            conversationResponse.statusCode == 201) {
          // Try to extract conversation ID
          String? conversationId;
          final data = conversationResponse.data;

          if (data is Map) {
            // First look for direct conversation_id or chat_id
            conversationId = data['conversation_id']?.toString() ??
                data['chat_id']?.toString() ??
                data['id']?.toString();

            // If not found, try to extract from nested data
            if (conversationId == null && data['data'] is Map) {
              final nestedData = data['data'] as Map;
              conversationId = nestedData['conversation_id']?.toString() ??
                  nestedData['chat_id']?.toString() ??
                  nestedData['id']?.toString();

              // Look one level deeper if needed
              if (conversationId == null && nestedData['conversation'] is Map) {
                final conversation = nestedData['conversation'] as Map;
                conversationId = conversation['id']?.toString();
              }
            }
          }

          if (conversationId != null) {
            // Now send message to this conversation
            final msgResponse = await _apiClient.post(
              '/chat/message/send',
              data: {
                'conversation_id': conversationId,
                'content': content,
              },
            );

            debugPrint(
                'Message send response: ${msgResponse.statusCode}, ${msgResponse.data}');

            if (msgResponse.statusCode == 200 ||
                msgResponse.statusCode == 201) {
              debugPrint(
                  '✅ Successfully sent invite message using conversation approach');
              return true; // Success!
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ Error with conversation approach: $e');
        // Continue to next approach if this fails
      }

      // If we've reached here, all approaches failed
      debugPrint('❌ All invite sending approaches failed');
      return false;
    } catch (e) {
      debugPrint('❌ ERROR sending group invite: $e');
      if (e is DioException && e.response != null) {
        debugPrint(
            'Response error: ${e.response!.statusCode}, ${e.response!.data}');
      }
      return false;
    }
  }

  // Join a group chat using an invite link/token
  Future<bool> joinGroupChatViaInviteLink(String inviteLink) async {
    try {
      debugPrint('===== JOINING GROUP VIA INVITE LINK =====');
      debugPrint('Invite link: $inviteLink');

      // Extract the token from the invite link
      final Uri uri = Uri.parse(inviteLink);
      final String? token = uri.queryParameters['token'];

      if (token == null) {
        debugPrint('❌ No token found in invite link');
        return false;
      }

      // Try to decode the token to get the group_chat_id
      String? groupChatId;

      // Option 1: Try joining via the invite endpoint with the token
      try {
        final response = await _apiClient.post(
          '/group/invite/join',
          data: {
            'token': token,
          },
        );

        debugPrint(
            'Join via token response: ${response.statusCode}, ${response.data}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          debugPrint('✅ Successfully joined group chat via invite token');
          return true;
        }

        // If the above fails, try to extract the group ID from the token response
        if (response.data is Map && response.data['data'] is Map) {
          final Map<String, dynamic> data = response.data['data'];
          groupChatId =
              data['group_id']?.toString() ?? data['group_chat_id']?.toString();

          if (groupChatId != null) {
            debugPrint('Found group chat ID in response: $groupChatId');
          }
        }
      } catch (e) {
        debugPrint('Error joining via token: $e');
        // Continue to try other methods
      }

      // Option 2: If we have the groupChatId, try joining directly
      if (groupChatId != null) {
        return await joinGroupChat(groupChatId);
      }

      // Option 3: Try to extract group_chat_id from the token itself (if it's a JWT)
      try {
        // Simple JWT structure - split by dots
        final parts = token.split('.');
        if (parts.length >= 2) {
          // Decode the payload (middle part)
          final String normalizedPayload = base64Normalize(parts[0]);
          final payloadBytes = base64Decode(normalizedPayload);
          final payloadString = String.fromCharCodes(payloadBytes);
          final Map<String, dynamic> payload = jsonDecode(payloadString);

          // Extract group chat ID from payload
          groupChatId = payload['group_chat_id']?.toString();

          if (groupChatId != null) {
            debugPrint('Extracted group chat ID from token: $groupChatId');
            return await joinGroupChat(groupChatId);
          }
        }
      } catch (e) {
        debugPrint('Error decoding token: $e');
        // Continue to try full URL as fallback
      }

      // Option 4: As a last resort, try the full URL as the endpoint
      try {
        final directResponse = await _apiClient.get(inviteLink);
        debugPrint('Direct invite link response: ${directResponse.statusCode}');

        return directResponse.statusCode == 200 ||
            directResponse.statusCode == 201;
      } catch (e) {
        debugPrint('Error with direct invite link: $e');
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error joining group via invite link: $e');
      return false;
    }
  }

  // Helper method to normalize base64 strings for decoding
  String base64Normalize(String input) {
    String output = input.replaceAll('-', '+').replaceAll('_', '/');
    switch (output.length % 4) {
      case 0:
        break;
      case 2:
        output += '==';
        break;
      case 3:
        output += '=';
        break;
      default:
        throw Exception('Illegal base64 string.');
    }
    return output;
  }
}
