import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/message.dart';
import '../repositories/chat_repository.dart';
import '../repositories/group_chat_repository.dart';

// Create a separate repository provider for messages to avoid circular dependencies
final messageRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository();
});

// States for message fetch
enum MessageFetchState { initial, loading, success, error }

// Provider for message fetch state
final messageStateProvider = StateProvider<MessageFetchState>((ref) {
  return MessageFetchState.initial;
});

// Provider for message fetch error
final messageErrorProvider = StateProvider<String?>((ref) {
  return null;
});

// Messages Provider
final messagesProvider =
    StateNotifierProvider<MessagesNotifier, Map<String, List<Message>>>(
  (ref) => MessagesNotifier(ref),
);

class MessagesNotifier extends StateNotifier<Map<String, List<Message>>> {
  final Ref _ref;
  // Using ChatRepository for API calls
  late final ChatRepository _chatRepository;
  late final GroupChatRepository _groupChatRepository;

  MessagesNotifier(this._ref) : super({}) {
    _chatRepository = ChatRepository();
    _groupChatRepository = GroupChatRepository();
  }

  // Method to get messages for a specific chat
  List<Message> getMessagesForChat(String chatId) {
    return state[chatId] ?? [];
  }

  // Method to fetch messages from the API
  Future<void> fetchMessages(String chatId, {bool isGroup = false}) async {
    try {
      Map<String, dynamic> apiResponse;

      if (isGroup) {
        apiResponse = await _groupChatRepository.getGroupMessages(chatId);
      } else {
        apiResponse = await _chatRepository.getDirectChatMessages(chatId);
      }

      // Extract messages from the API response
      final List<dynamic>? messagesList = isGroup
          ? apiResponse['messages'] as List<dynamic>?
          : (apiResponse['messages'] as List<dynamic>?);

      if (messagesList == null) {
        debugPrint('API returned null or invalid messages list');
        return;
      }

      // Parse messages from API data
      final List<Message> messages = messagesList
          .map((msgData) => Message.fromApi(msgData as Map<String, dynamic>))
          .toList();

      // Sort messages by timestamp in ascending order (oldest first)
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      // Update state with the fetched messages
      state = {
        ...state,
        chatId: messages,
      };

      debugPrint(
          'Updated state with ${messages.length} messages for chat $chatId');
    } catch (e) {
      debugPrint('Error fetching messages for chat $chatId: $e');
      // Re-throw so the UI can handle the error
      rethrow;
    }
  }

  // Method to add a new message to a chat
  void addMessage(String chatId, Message message) {
    final currentMessages = state[chatId] ?? [];
    state = {
      ...state,
      chatId: [...currentMessages, message],
    };
  }

  // Method to remove a message from a chat
  void removeMessage(String chatId, String messageId) {
    final currentMessages = state[chatId] ?? [];
    state = {
      ...state,
      chatId:
          currentMessages.where((message) => message.id != messageId).toList(),
    };
  }

  // Method to replace a temporary message with a real one
  void replaceMessage(String chatId, String oldMessageId, Message newMessage) {
    final currentMessages = state[chatId] ?? [];
    final updatedMessages = currentMessages.map((message) {
      if (message.id == oldMessageId) {
        return newMessage;
      }
      return message;
    }).toList();

    state = {
      ...state,
      chatId: updatedMessages,
    };
  }

  // Method to clear all messages in a chat
  void clearChat(String chatId) {
    state = {
      ...state,
      chatId: [],
    };
  }

  // Direct state update method for socket message handling
  void updateDirectly(Map<String, List<Message>> newState) {
    state = newState;
  }

  // Method to update a message after editing
  void updateMessage(String chatId, Message updatedMessage) {
    final currentMessages = state[chatId] ?? [];
    final updatedMessages = currentMessages.map((message) {
      if (message.id == updatedMessage.id) {
        return updatedMessage;
      }
      return message;
    }).toList();

    state = {
      ...state,
      chatId: updatedMessages,
    };
  }
}
