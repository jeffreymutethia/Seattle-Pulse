import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat.dart';
import '../models/chat_user.dart';
import '../models/message.dart';
import '../repositories/chat_repository.dart';
import '../../../core/services/socket_service.dart';
import 'message_provider.dart';

// Provider for ChatRepository
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository();
});

// Provider for Socket Service
final socketProvider = Provider<SocketService>((ref) {
  return SocketService.instance;
});

// States for chat provider
enum ChatFetchState { initial, loading, success, error }

// Provider with state
final chatStateProvider = StateProvider<ChatFetchState>((ref) {
  return ChatFetchState.initial;
});

// Provider for error messages
final chatErrorProvider = StateProvider<String?>((ref) {
  return null;
});

// Provider for current user ID (this would typically come from auth provider)
// Using a fixed ID to match the API data - in a real app this would come from auth
final currentUserIdProvider = StateProvider<String>((ref) {
  // Fixed to match API format where sender_id is numeric
  debugPrint("Creating current user id provider with fixed ID for testing");
  // Updated to match the user's actual ID from the API (user1)
  return '13'; // User1's ID based on the API response
});

// Provider for the list of chats
final chatsProvider = StateNotifierProvider<ChatsNotifier, List<Chat>>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  final socketService = ref.watch(socketProvider);
  final userId = ref.watch(currentUserIdProvider);

  return ChatsNotifier(repository, socketService, userId, ref);
});

class ChatsNotifier extends StateNotifier<List<Chat>> {
  final ChatRepository _repository;
  final SocketService _socketService;
  final String _userId;
  final Ref _ref;

  ChatsNotifier(this._repository, this._socketService, this._userId, this._ref)
      : super([]) {
    // Initialize
    _initialize();
  }

  Future<void> _initialize() async {
    // Initialize socket for real-time updates
    await _socketService.initSocket(_userId);

    // Listen for incoming messages
    _socketService.addNotificationListener(_handleNewMessage);

    // Fetch chats (if not in dummy mode)
    fetchChats();
  }

  void _handleNewMessage(dynamic data) {
    try {
      debugPrint('Received new message: $data');

      // Extract data from notification
      final chatId = data['chat_id']?.toString();
      final senderId = data['sender_id']?.toString();
      final content = data['content'];

      // Return early if any required data is missing
      if (chatId == null || senderId == null || content == null) {
        debugPrint('⚠️ Warning: Received message with missing data, skipping');
        return;
      }

      debugPrint(
          'Socket notification for chatId=$chatId, senderId=$senderId, content=$content');

      // Find the chat - first check if it exists
      final chatIndex = state.indexWhere((chat) => chat.id == chatId);
      if (chatIndex >= 0) {
        final chat = state[chatIndex];
        debugPrint('Found chat with id=$chatId, adding incoming message to it');

        // Create a new message with proper ID format
        final uniqueId = 'msg_${DateTime.now().millisecondsSinceEpoch}';
        final newMessage = Message(
          id: data['id']?.toString() ?? uniqueId,
          senderId: senderId,
          content: content,
          timestamp: DateTime.now(),
          isRead: false,
          chatId: chatId,
        );

        // Update the chat's last message
        final updatedChat = chat.copyWith(lastMessage: newMessage);

        // First remove the chat from its current position
        final newState = List<Chat>.from(state);
        newState.removeAt(chatIndex);

        // Then insert it at the beginning (most recent)
        newState.insert(0, updatedChat);

        // Update the state with this reordered list
        state = newState;

        // Make sure the message is also added to the message provider
        _ref.read(messagesProvider.notifier).addMessage(chatId, newMessage);

        debugPrint(
            'Successfully added new socket message to messages provider');
        debugPrint(
            'Updated chat ${updatedChat.id} with last message: ${updatedChat.lastMessage?.content}');
      } else {
        debugPrint('⚠️ Warning: Received message for unknown chat ID: $chatId');
      }
    } catch (e) {
      debugPrint('Error handling new message: $e');
    }
  }

  // Fetch all chats from API
  Future<void> fetchChats() async {
    try {
      _ref.read(chatStateProvider.notifier).state = ChatFetchState.loading;

      // Use the real API to fetch chats
      final chatsData = await _repository.getAllChats();
      debugPrint('Fetched ${chatsData.length} chats from API');

      final chats = chatsData.map((data) => Chat.fromApi(data)).toList();
      state = chats;

      // Sort chats by most recent message
      state.sort((a, b) {
        final aTime = a.lastMessage?.timestamp ?? a.createdAt;
        final bTime = b.lastMessage?.timestamp ?? b.createdAt;
        return bTime
            .compareTo(aTime); // Sort in descending order (newest first)
      });

      _ref.read(chatStateProvider.notifier).state = ChatFetchState.success;
    } catch (e) {
      debugPrint('Error fetching chats: $e');
      _ref.read(chatStateProvider.notifier).state = ChatFetchState.error;
      _ref.read(chatErrorProvider.notifier).state = e.toString();

      // Don't fallback to dummy data, keep empty state until API is successful
      state = [];
    }
  }

  // Get all chats
  List<Chat> getAllChats() {
    return state;
  }

  // Get private chats
  List<Chat> getPrivateChats() {
    return state.where((chat) => chat.type == ChatType.private).toList();
  }

  // Get group chats
  List<Chat> getGroupChats() {
    return state.where((chat) => chat.type == ChatType.group).toList();
  }

  // Get chat by id
  Chat? getChatById(String chatId) {
    try {
      return state.firstWhere((chat) => chat.id == chatId);
    } catch (e) {
      return null;
    }
  }

  // Start a new chat with a user
  Future<Chat?> startChat(ChatUser user) async {
    try {
      _ref.read(chatStateProvider.notifier).state = ChatFetchState.loading;

      // Check if chat already exists
      final existingChat = state.firstWhere(
        (chat) =>
            chat.type == ChatType.private &&
            chat.participants.any((participant) => participant.id == user.id),
        orElse: () => Chat(
          id: 'chat_${DateTime.now().millisecondsSinceEpoch}',
          name: user.name,
          imageUrl: user.imageUrl,
          participants: [user],
        ),
      );

      if (state.contains(existingChat)) {
        _ref.read(chatStateProvider.notifier).state = ChatFetchState.success;
        return existingChat;
      }

      // Start chat via API
      debugPrint('===== STARTING CHAT WITH USER =====');
      debugPrint('User ID: ${user.id}, Name: ${user.name}');
      final response = await _repository.startDirectChat(user.id);
      debugPrint('Chat API raw response: $response');

      // Extract the chat ID from response
      String? chatId;

      // APPROACH 1: Navigate through the response structure to find the chat ID
      if (response.containsKey('chat') && response['chat'] is Map) {
        // Format: data.chat.id
        final chatData = response['chat'] as Map<String, dynamic>;
        chatId = chatData['id']?.toString();
        debugPrint('Found chat ID in response.chat.id: $chatId');
      } else if (response.containsKey('chat_id')) {
        // Format: data.chat_id
        chatId = response['chat_id'].toString();
        debugPrint('Found chat ID in response.chat_id: $chatId');
      } else if (response.containsKey('id')) {
        // Format: data.id
        chatId = response['id'].toString();
        debugPrint('Found chat ID in response.id: $chatId');
      }

      // APPROACH 2: If the standard paths don't work, recursive search
      if (chatId == null) {
        debugPrint('Searching recursively for chat ID in response');

        // Define a recursive search function to find the first ID
        void findId(dynamic obj, String path) {
          if (obj is Map) {
            // First check for id key with a value
            if (obj.containsKey('id') && obj['id'] != null) {
              chatId ??= obj['id'].toString();
              debugPrint('Found potential chat ID at $path.id: ${obj['id']}');
            }

            // Then look for a chat object with an id
            if (obj.containsKey('chat') && obj['chat'] is Map) {
              final chat = obj['chat'] as Map;
              if (chat.containsKey('id') && chat['id'] != null) {
                chatId ??= chat['id'].toString();
                debugPrint(
                    'Found potential chat ID at $path.chat.id: ${chat['id']}');
              }
            }

            // Continue searching nested objects if we haven't found an ID yet
            if (chatId == null) {
              obj.forEach((key, value) {
                if (value is Map || value is List) {
                  findId(value, '$path.$key');
                }
              });
            }
          } else if (obj is List && chatId == null) {
            // Search in list items
            for (int i = 0; i < obj.length; i++) {
              findId(obj[i], '$path[$i]');
            }
          }
        }

        findId(response, 'root');
      }

      // FALLBACK: If we still can't find a chat ID, use a generated one
      if (chatId == null) {
        chatId = 'chat_${DateTime.now().millisecondsSinceEpoch}';
        debugPrint('⚠️ No chat ID found in response, using generated: $chatId');
      } else {
        debugPrint('✅ Using chat ID: $chatId');
      }

      // At this point chatId is guaranteed to be non-null
      final String nonNullChatId = chatId!; // Force non-null with assertion

      // Create a Chat object with the extracted ID
      final chat = Chat(
        id: nonNullChatId,
        name: user.name,
        imageUrl: user.imageUrl,
        type: ChatType.private,
        participants: [user],
        createdAt: DateTime.now(),
      );

      // Add chat to state
      state = [...state, chat];
      _ref.read(chatStateProvider.notifier).state = ChatFetchState.success;
      return chat;
    } catch (e) {
      debugPrint('❌ Error starting chat: $e');
      _ref.read(chatStateProvider.notifier).state = ChatFetchState.error;
      _ref.read(chatErrorProvider.notifier).state = e.toString();
      return null;
    }
  }

  // Send a message in chat
  Future<bool> sendMessage(String chatId, String content) async {
    try {
      // Get the chat
      final chat = getChatById(chatId);
      if (chat == null) return false;

      // Send message via API
      final messageData = await _repository.sendDirectMessage(chatId, content);
      final message = Message.fromApi(messageData);

      debugPrint(
          'Message sent successfully: ${message.id}, content: ${message.content}');

      // Update the chat's last message
      final updatedChat = chat.copyWith(lastMessage: message);

      // Find the chat index
      final chatIndex = state.indexWhere((c) => c.id == chatId);

      // Move this chat to the top of the list (most recent)
      final newState = List<Chat>.from(state);
      if (chatIndex >= 0) {
        // Remove from current position
        newState.removeAt(chatIndex);
      }
      // Add to the top
      newState.insert(0, updatedChat);

      // Update the state with reordered list
      state = newState;

      debugPrint(
          'Chat ${updatedChat.id} moved to top of chat list with last message: ${updatedChat.lastMessage?.content}');

      // Add message to messages provider
      _ref.read(messagesProvider.notifier).addMessage(chatId, message);
      return true;
    } catch (e) {
      debugPrint('Error sending message: $e');
      return false;
    }
  }

  // Mark all messages in a chat as read
  Future<void> markChatAsRead(String chatId) async {
    try {
      // Find the chat
      final chatIndex = state.indexWhere((chat) => chat.id == chatId);
      if (chatIndex < 0) return;

      final chat = state[chatIndex];

      // If the last message is already read, no need to update
      if (chat.lastMessage?.isRead == true) return;

      // Create updated chat with read message
      final updatedLastMessage = chat.lastMessage?.copyWith(isRead: true);
      final updatedChat = chat.copyWith(lastMessage: updatedLastMessage);

      // Update the chat in the state
      final newState = List<Chat>.from(state);
      newState[chatIndex] = updatedChat;
      state = newState;

      // Also mark all messages as read in the messages provider
      // _ref.read(messagesProvider.notifier).markAllAsRead(chatId);

      debugPrint('Marked all messages in chat $chatId as read');

      // TODO: In a real implementation, you would call an API to mark messages as read
      // await _repository.markChatAsRead(chatId);
    } catch (e) {
      debugPrint('Error marking chat as read: $e');
    }
  }

  // Delete a chat
  Future<bool> deleteChat(String chatId) async {
    try {
      // Delete chat via API
      final success = await _repository.deleteChat(chatId);
      if (!success) return false;

      // Update state
      state = state.where((chat) => chat.id != chatId).toList();

      // Clear messages for this chat
      _ref.read(messagesProvider.notifier).clearChat(chatId);

      return true;
    } catch (e) {
      debugPrint('Error deleting chat: $e');
      return false;
    }
  }

  // Add new chat
  void addChat(Chat chat) {
    if (!state.any((c) => c.id == chat.id)) {
      state = [...state, chat];
    }
  }

  // Update existing chat
  void updateChat(Chat updatedChat) {
    state = [
      for (final chat in state)
        if (chat.id == updatedChat.id) updatedChat else chat
    ];
  }

  // Update all chats at once (for reordering)
  void updateAllChats(List<Chat> newChats) {
    debugPrint('Updating all chats - count: ${newChats.length}');
    state = newChats;
  }
}

// Provider for current active chat
final currentChatProvider = StateProvider<Chat?>((ref) => null);

// Provider to check if current user is an admin in the current group chat
final isUserAdminProvider = Provider<bool>((ref) {
  final currentChat = ref.watch(currentChatProvider);
  final currentUserId = ref.watch(currentUserIdProvider);

  if (currentChat == null || currentChat.type != ChatType.group) {
    return false;
  }

  // Check if current user is in admin list
  // For simplicity, assume the creator is the admin
  return currentChat.createdBy == currentUserId;
});

// Provider for chat messages
final chatMessagesProvider =
    Provider.family<List<Message>, String>((ref, chatId) {
  return ref.watch(messagesProvider.notifier).getMessagesForChat(chatId);
});

// Provider for suggested users to add to chats
final suggestedUsersProvider = Provider<List<ChatUser>>((ref) {
  final existingChats = ref.watch(chatsProvider);
  final privateChats =
      existingChats.where((chat) => chat.type == ChatType.private).toList();
  final currentUserId = ref.watch(currentUserIdProvider);

  // Get users that don't already have a private chat with current user
  final chatUserIds = privateChats
      .map((chat) => chat.participants
          .where((user) => user.id != currentUserId)
          .map((user) => user.id))
      .expand((ids) => ids)
      .toSet();

  // Create some sample users to display
  final sampleUsers = [
    ChatUser(
      id: '16',
      name: 'First4 Last4',
      imageUrl: 'https://picsum.photos/640/480?random=16',
      username: 'user4',
      email: 'user4@example.com',
      isOnline: true,
    ),
    ChatUser(
      id: '17',
      name: 'First5 Last5',
      imageUrl: 'https://picsum.photos/640/480?random=17',
      username: 'user5',
      email: 'user5@example.com',
      isOnline: false,
    ),
    ChatUser(
      id: '18',
      name: 'First6 Last6',
      imageUrl: 'https://picsum.photos/640/480?random=18',
      username: 'user6',
      email: 'user6@example.com',
      isOnline: true,
    ),
    ChatUser(
      id: '19',
      name: 'First7 Last7',
      imageUrl: 'https://picsum.photos/640/480?random=19',
      username: 'user7',
      email: 'user7@example.com',
      isOnline: false,
    ),
  ];

  // Filter out users that are already in chats with the current user
  return sampleUsers.where((user) => !chatUserIds.contains(user.id)).toList();
});
