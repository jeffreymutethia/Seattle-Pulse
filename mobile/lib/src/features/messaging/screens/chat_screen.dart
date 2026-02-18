import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../core/services/socket_service.dart';
import '../models/chat.dart';
import '../models/chat_user.dart';
import '../models/message.dart';
import '../providers/chat_provider.dart';
import '../providers/message_provider.dart';
import '../repositories/chat_repository.dart';
import '../repositories/group_chat_repository.dart';
import '../widgets/avatar.dart';
import '../widgets/message_bubble.dart';
import 'group_info_screen.dart';
import 'add_member_screen.dart';
import '../screens/create_group_screen.dart';
import '../widgets/invite_members_dialog.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String? title;
  final bool isGroupChat;
  final Chat chat;

  const ChatScreen({
    required this.chatId,
    this.title,
    this.isGroupChat = false,
    required this.chat,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Added missing state variables
  bool _isLoading = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();

    // Set up socket listeners for this specific chat
    _setupSocketListeners();

    // Schedule loading chat after the widget is built
    // This ensures the widget is fully initialized before making API calls
    Future.microtask(() async {
      await _loadChat();

      // Mark all messages as read after loading
      _markChatAsRead();
    });

    // Schedule a scroll to bottom after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  // Method to get the current user ID consistently from the provider
  String get _getCurrentUserId => ref.read(currentUserIdProvider);

  void _setupSocketListeners() {
    debugPrint('Setting up socket listeners for chat ${widget.chatId}');

    final socketService = ref.read(socketProvider);
    final currentUserId = _getCurrentUserId;

    debugPrint('⚠️ Using current user ID: $currentUserId for socket listeners');

    // Direct handler to ensure we capture all socket events regardless of source
    socketService.addNotificationListener((data) {
      if (!mounted) return;

      debugPrint('💬 Received socket notification in chat screen: $data');

      // Process all types of socket message formats
      String? chatId;
      String? senderId;
      String? content;
      String? messageId;

      // Handle different message formats
      if (data is Map) {
        // Format 1: Direct notification with chat_id
        if (data['chat_id'] != null) {
          chatId = data['chat_id'].toString();
          senderId = data['sender_id']?.toString();
          content = data['content']?.toString();
          messageId = data['id']?.toString();
        }
        // Format 2: Nested message data
        else if (data['message_data'] != null && data['message_data'] is Map) {
          final messageData = data['message_data'] as Map;
          chatId = messageData['chat_id']?.toString();
          senderId = messageData['sender_id']?.toString();
          content = messageData['content']?.toString();
          messageId = messageData['id']?.toString();
        }

        // Add a timestamp to make this unique across listeners
        messageId = messageId ??
            'notification_${DateTime.now().millisecondsSinceEpoch}';
      }

      // Process if this is a valid message for the current chat
      if (chatId != null &&
          chatId == widget.chatId &&
          content != null &&
          senderId != null) {
        debugPrint(
            '💬 Processing socket notification message for current chat $chatId');
        // Wait a tiny bit to avoid collision with other handlers
        Future.delayed(const Duration(milliseconds: 50), () {
          _processIncomingMessage(chatId!, senderId!, content!, messageId);
        });
      }
    });

    // Keep existing specific listeners as a backup - using a different event name
    socketService.on('new_message', (data) {
      if (!mounted) return;

      debugPrint('Socket received direct new_message: $data');

      // Verify this message is for the current chat
      if (data != null && data['chat_id'] != null) {
        final messageChatId = data['chat_id'].toString();

        // Check if this message belongs to the current chat
        if (messageChatId == widget.chatId) {
          final senderId = data['sender_id']?.toString() ?? '';
          final content = data['content']?.toString() ?? '';
          final messageId = 'direct_${DateTime.now().millisecondsSinceEpoch}';

          // Use a small delay to avoid collision with the notification handler
          Future.delayed(const Duration(milliseconds: 100), () {
            _processIncomingMessage(
                messageChatId, senderId, content, messageId);
          });
        }
      }
    });
  }

  // Extract message processing logic to a separate method
  void _processIncomingMessage(
      String chatId, String senderId, String content, String? messageId) {
    if (!mounted) return;

    try {
      debugPrint('⚡ DIRECT PROCESSING: Processing message for chat $chatId');
      debugPrint('Content: $content, Sender: $senderId');

      final currentUserId = _getCurrentUserId;
      final myUserId = currentUserId.toString().trim();

      // Skip messages from myself
      final isFromMe = senderId.toString().trim() == myUserId;
      if (isFromMe) {
        debugPrint('Skipping message from myself (ID: $myUserId)');
        return;
      }

      // Create a unique message ID to avoid duplicates
      final uniqueMessageId = messageId ??
          'socket_${DateTime.now().millisecondsSinceEpoch}_${content.hashCode}';

      // DIRECT STATE ACCESS: Get current messages from state
      final messagesState = ref.read(messagesProvider);
      final currentMessages = messagesState[chatId] ?? [];

      // Check if this message already exists by content and sender
      final messageExists = currentMessages.any((m) =>
          m.id == uniqueMessageId ||
          (m.content == content &&
              m.senderId == senderId &&
              m.timestamp.difference(DateTime.now()).inMilliseconds.abs() <
                  500));

      if (messageExists) {
        debugPrint('⚡ DIRECT PROCESSING: Message already exists, skipping');
        return;
      }

      // Create a new message
      final newMessage = Message(
        id: uniqueMessageId,
        senderId: senderId,
        content: content,
        timestamp: DateTime.now(),
        isRead: false,
        chatId: chatId,
      );

      debugPrint(
          '⚡ DIRECT PROCESSING: Adding message to state: ${newMessage.id}');

      // FORCE UI UPDATE with setState
      setState(() {
        // Add message directly to MessagesNotifier
        final updatedMessages = [...currentMessages, newMessage];

        // Create new state by adding this message to the existing state
        final newState = Map<String, List<Message>>.from(messagesState);
        newState[chatId] = updatedMessages;

        // Force update the provider state
        ref.read(messagesProvider.notifier).updateDirectly(newState);
      });

      debugPrint('⚡ DIRECT PROCESSING: Message added, forcing UI refresh');

      // Scroll to bottom after a short delay
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) _scrollToBottom();
        });
      });
    } catch (e) {
      debugPrint('Error directly processing message: $e');
    }
  }

  @override
  void dispose() {
    // Store references locally before cleanup to avoid "Cannot use ref after widget was disposed" error
    SocketService? socketServiceInstance;
    try {
      // Only get the socketService if it exists, wrapped in try-catch to avoid errors
      socketServiceInstance = ref.read(socketProvider);
    } catch (e) {
      debugPrint('Error accessing socketProvider during disposal: $e');
      socketServiceInstance = null;
    }

    // Clean up controllers first
    _messageController.dispose();
    _scrollController.dispose();

    // Then clean up socket listeners if the service is available
    if (socketServiceInstance != null) {
      try {
        socketServiceInstance.off('new_message');
        socketServiceInstance.removeAllListeners();
        debugPrint('Successfully cleaned up socket listeners');
      } catch (e) {
        debugPrint('Error cleaning up socket listeners: $e');
      }
    }

    // Call super.dispose() last
    super.dispose();
  }

  Future<void> _loadChat() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('Loading messages for chat ${widget.chatId}');

      // Use the notifier to fetch messages - make sure this awaits the API call
      await ref.read(messagesProvider.notifier).fetchMessages(
            widget.chatId,
            isGroup: widget.isGroupChat,
          );

      // Debug print to verify messages were loaded
      final messages =
          ref.read(messagesProvider.notifier).getMessagesForChat(widget.chatId);
      debugPrint(
          'Loaded ${messages.length} messages for chat ${widget.chatId}');

      // Schedule scrolling to bottom after UI updates
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      debugPrint('Error loading chat messages: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load messages: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      debugPrint('Scrolling to bottom of message list');
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      debugPrint('ScrollController has no clients yet, scheduling scroll');
      // Try again after a short delay if controller is not attached yet
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _scrollToBottom();
      });
    }
  }

  Future<void> _sendMessage() async {
    final messageContent = _messageController.text.trim();
    if (messageContent.isEmpty) return;

    setState(() {
      _isSending = true;
    });

    try {
      debugPrint('Sending message to chat ${widget.chatId}: $messageContent');

      // Clear the input field immediately for better UX
      _messageController.clear();

      // Get current user ID and timestamp
      final currentUserId = _getCurrentUserId;
      final timestamp = DateTime.now();

      // Create a temporary message to display immediately
      final tempMessageId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      final tempMessage = Message(
        id: tempMessageId,
        senderId: currentUserId,
        content: messageContent,
        timestamp: timestamp,
        isRead: false,
        chatId: widget.chatId,
      );

      // Add the temporary message to the local state
      final messagesNotifier = ref.read(messagesProvider.notifier);
      messagesNotifier.addMessage(widget.chatId, tempMessage);

      // Scroll to bottom to show the new message
      _scrollToBottom();

      // Send message to server
      Message? serverMessage;
      if (widget.isGroupChat) {
        // Send message to group chat
        final groupRepository = GroupChatRepository();
        serverMessage = await groupRepository.sendGroupMessage(
            widget.chatId, messageContent);
      } else {
        // Send message to direct chat
        final chatRepository = ChatRepository();
        final response = await chatRepository.sendDirectMessage(
            widget.chatId, messageContent);
        if (response.containsKey('message_data')) {
          serverMessage =
              Message.fromApi(response['message_data'] as Map<String, dynamic>);
        }
      }

      // If we got a response from the server, replace the temp message with the real one
      if (serverMessage != null) {
        messagesNotifier.replaceMessage(
            widget.chatId, tempMessageId, serverMessage);
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _showDeleteAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Messages'),
        content: const Text(
          'Are you sure you want to delete all messages in this chat? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteAllMessages();
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAllMessages() async {
    // Clear messages from the local state
    ref.read(messagesProvider.notifier).clearChat(widget.chatId);
  }

  Widget _buildMessageList() {
    // Get messages for this chat
    final messages =
        ref.watch(messagesProvider.notifier).getMessagesForChat(widget.chatId);

    // Get current user ID from the provider (this is the logged-in user ID)
    final currentUserId = ref.watch(currentUserIdProvider);

    debugPrint('Building message list with currentUserId=$currentUserId');

    if (messages.isEmpty) {
      return const Center(
        child: Text(
          'No messages yet',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      // Setting reverse to false to have newest at bottom
      reverse: false,
      itemCount: messages.length,
      // Increased padding for better spacing
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      itemBuilder: (context, index) {
        final message = messages[index];
        final previousMessage = index > 0 ? messages[index - 1] : null;
        final nextMessage =
            index < messages.length - 1 ? messages[index + 1] : null;

        // Clean up IDs to ensure proper comparison
        final messageSenderId = message.senderId.toString().trim();
        final myUserId = currentUserId.toString().trim();

        // Debug log for ID comparison
        debugPrint(
            'Message sender check - message senderId: "$messageSenderId", my userId: "$myUserId"');

        // FIXED LOGIC:
        // - If message sender_id == current user's ID, message is FROM current user (show on RIGHT)
        // - If message sender_id != current user's ID, message is FROM someone else (show on LEFT)
        final isFromMe = messageSenderId == myUserId;

        // Debug this message
        debugPrint(
            'Message #$index: id=${message.id}, senderId=$messageSenderId, isFromMe=$isFromMe');

        // Check if this is the first message in a group from the same sender
        final isFirstInGroup = previousMessage == null ||
            previousMessage.senderId.toString().trim() != messageSenderId;

        // Check if this is the last message in a group from the same sender
        final isLastInGroup = nextMessage == null ||
            nextMessage.senderId.toString().trim() != messageSenderId;

        // Add extra spacing between different sender groups
        final topPadding = isFirstInGroup ? 8.0 : 2.0;
        final bottomPadding = isLastInGroup ? 8.0 : 2.0;

        // Show avatar only for the first message in a group from other users
        final showAvatar = isFirstInGroup && !isFromMe;

        // Show timestamp only for the last message in a group
        final showTimestamp = isLastInGroup;

        // Determine the bubble position within a group for correct border radius
        String bubblePosition = "single"; // Default for standalone messages
        if (!isFirstInGroup && !isLastInGroup) {
          bubblePosition = "middle";
        } else if (isFirstInGroup && !isLastInGroup) {
          bubblePosition = "top";
        } else if (!isFirstInGroup && isLastInGroup) {
          bubblePosition = "bottom";
        }

        return Padding(
          padding: EdgeInsets.only(top: topPadding, bottom: bottomPadding),
          child: MessageBubble(
            key: ValueKey(message.id),
            message: message,
            isFromMe: message.senderId == currentUserId,
            showAvatar: showAvatar,
            showTimestamp: showTimestamp,
            senderName: widget.isGroupChat && showAvatar
                ? message.sender?.name ?? "User"
                : null,
            senderImageUrl: message.sender?.imageUrl,
            bubblePosition: bubblePosition,
            isGroupChat: widget.isGroupChat,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get messages for this chat
    final messages =
        ref.watch(messagesProvider.notifier).getMessagesForChat(widget.chatId);
    // Get current user ID
    final currentUserId = ref.watch(currentUserIdProvider);

    // Debug info
    debugPrint('Building chat screen with ${messages.length} messages');
    debugPrint('Current user ID: $currentUserId');

    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildMessageList(),
          ),

          // Message input
          _buildMessageInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    // Get current user ID for online status check
    final currentUserId = ref.watch(currentUserIdProvider);

    // Determine if the other user is online (for direct chats)
    bool isOnline = false;
    if (!widget.isGroupChat) {
      final otherUser = widget.chat.participants.firstWhere(
        (user) => user.id != currentUserId,
        orElse: () => widget.chat.participants.first,
      );
      isOnline = otherUser.isOnline;
    }

    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          Avatar(
            imageUrl: widget.chat.imageUrl,
            size: 40,
            isOnline: isOnline,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              widget.chat.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.delete),
          tooltip: 'Delete All Messages',
          onPressed: _showDeleteAllDialog,
        ),
        if (widget.isGroupChat)
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _showGroupOptionsDropdown();
            },
          ),
        if (widget.isGroupChat)
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Invite Members',
            onPressed: _showInviteMembersDialog,
          ),
      ],
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(
          color: Colors.grey[300],
          height: 1.0,
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: () {
              // TODO: Handle file attachment
            },
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              enabled: !_isSending,
            ),
          ),
          IconButton(
            icon: _isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            color: Colors.blue,
            onPressed: _isSending ? null : _sendMessage,
          ),
        ],
      ),
    );
  }

  void _showGroupOptionsDropdown() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.group),
                title: const Text('Group Info'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GroupInfoScreen(chat: widget.chat),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_add),
                title: const Text('Add Member'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddMemberScreen();
                },
              ),
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('Generate Invite Link'),
                onTap: () {
                  Navigator.pop(context);
                  _generateInviteLink();
                },
              ),
              ListTile(
                leading: const Icon(Icons.exit_to_app),
                title: const Text('Leave Group'),
                onTap: () {
                  Navigator.pop(context);
                  _showLeaveGroupDialog();
                },
              ),
              if (_isUserAdminOrOwner())
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Delete Group',
                      style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteGroupDialog();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showInviteMemberBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _buildInviteMemberContent(),
    );
  }

  Widget _buildInviteMemberContent() {
    final suggestedUsers = ref.watch(suggestedUsersProvider);

    return StatefulBuilder(
      builder: (context, setState) {
        // Using StatefulBuilder to manage state within the bottom sheet
        final Set<String> selectedUserIds = {};

        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return Container(
              color: Colors.white,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Handle
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                          margin: const EdgeInsets.only(bottom: 16),
                        ),
                        const Text(
                          'Invite New Member',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Search box
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.0),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                      ),
                    ),
                  ),

                  // Selected users count
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Text(
                          'No users selected.',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Suggested label
                  const Padding(
                    padding:
                        EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Suggested',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // Suggested users list
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: suggestedUsers.length,
                      itemBuilder: (context, index) {
                        final user = suggestedUsers[index];
                        final isSelected = selectedUserIds.contains(user.id);

                        return ListTile(
                          leading: Avatar(
                            imageUrl: user.imageUrl,
                            size: 40.0,
                            isOnline: user.isOnline,
                          ),
                          title: Text(
                            user.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: user.location != null
                              ? Text(
                                  user.location!,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12.0,
                                  ),
                                )
                              : null,
                          trailing: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.blue : Colors.grey,
                                width: 2.0,
                              ),
                              color:
                                  isSelected ? Colors.blue : Colors.transparent,
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                selectedUserIds.remove(user.id);
                              } else {
                                selectedUserIds.add(user.id);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),

                  // Add button
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: () {
                        _addMembers(selectedUserIds);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: const Text(
                        'Add',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _addMembers(Set<String> selectedUserIds) {
    if (selectedUserIds.isEmpty) return;

    // Instead of using dummyUsers, we will use the suggestedUsers from provider
    final suggestedUsers = ref.read(suggestedUsersProvider);

    // Get the selected users from the suggestedUsers list
    final selectedUsers = suggestedUsers
        .where((user) => selectedUserIds.contains(user.id))
        .toList();

    // Add them to the current chat
    final updatedParticipants = [
      ...widget.chat.participants,
      ...selectedUsers,
    ];

    // Update the chat
    final updatedChat = widget.chat.copyWith(
      participants: updatedParticipants,
    );

    // Update the chat in the provider
    ref.read(chatsProvider.notifier).updateChat(updatedChat);
  }

  Future<void> _confirmDeleteChat() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Chat'),
        content: const Text(
          'Are you sure you want to leave this chat? This will delete the conversation and you will not receive any more messages.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (shouldDelete == true && mounted) {
      final success =
          await ref.read(chatsProvider.notifier).deleteChat(widget.chat.id);
      if (success) {
        // Return to inbox screen
        Navigator.of(context).pop();
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to leave chat. Please try again.'),
          ),
        );
      }
    }
  }

  // Mark all messages in this chat as read
  void _markChatAsRead() {
    if (!mounted) return;

    try {
      debugPrint('Marking all messages in chat ${widget.chatId} as read');
      ref.read(chatsProvider.notifier).markChatAsRead(widget.chatId);
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  void _showAddMemberScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMemberScreen(groupId: widget.chatId),
      ),
    ).then((_) {
      // Refresh the chat or members list if needed
    });
  }

  bool _isUserAdminOrOwner() {
    final currentUserId = ref.read(currentUserIdProvider);
    return widget.chat.isAdmin(currentUserId) ||
        widget.chat.createdBy?.id == currentUserId;
  }

  void _showDeleteGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: const Text(
            'Are you sure you want to delete this group? This action cannot be undone and all messages will be permanently deleted for everyone.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _deleteGroup();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteGroup() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      setState(() {
        _isLoading = true;
      });

      final groupRepository = GroupChatRepository();

      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Deleting group, please wait...')),
      );

      final success = await groupRepository.deleteGroup(widget.chatId);

      if (success) {
        // Successfully deleted the group, navigate back to inbox
        if (mounted) {
          scaffoldMessenger.clearSnackBars(); // Clear the "please wait" message
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Group deleted successfully')),
          );
          Navigator.of(context).pop();
        }
      } else {
        scaffoldMessenger.clearSnackBars();
        scaffoldMessenger.showSnackBar(
          const SnackBar(
              content: Text('Failed to delete group. Please try again.')),
        );
      }
    } catch (e) {
      debugPrint('Error deleting group: $e');

      // Extract and show a more user-friendly error message
      String errorMessage = 'Error: Failed to delete group';

      if (e is DioException) {
        if (e.response?.statusCode == 403) {
          errorMessage = 'You do not have permission to delete this group';
        } else if (e.response?.statusCode == 404) {
          errorMessage = 'Group not found';
        } else if (e.response?.data != null) {
          // Try to extract error message from response
          try {
            final responseData = e.response!.data;
            if (responseData is Map && responseData['message'] != null) {
              errorMessage = 'Error: ${responseData['message']}';
            }
          } catch (_) {
            // Use the default message if we can't parse the response
          }
        }
      }

      scaffoldMessenger.clearSnackBars();
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showLeaveGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: const Text(
            'Are you sure you want to leave this group? You will no longer receive messages from this group.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _leaveGroup();
            },
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  Future<void> _leaveGroup() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      setState(() {
        _isLoading = true;
      });

      final groupRepository = GroupChatRepository();
      final result = await groupRepository.leaveGroupChat(widget.chatId);

      if (result['success'] == true) {
        // Successfully left the group, navigate back to inbox
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Successfully left the group')),
          );
          Navigator.of(context).pop();
        }
      } else if (result['delete_required'] == true) {
        // Show confirmation for group deletion
        if (mounted) {
          _showGroupDeletionConfirmationDialog();
        }
      } else {
        // Show error message
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to leave group')),
        );
      }
    } catch (e) {
      debugPrint('Error leaving group chat: $e');
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error leaving group: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showGroupDeletionConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group?'),
        content: const Text(
            'You are the last member and owner of this group. Leaving will delete the group permanently. Continue?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _leaveGroupWithDeletion();
            },
            child: const Text('Delete Group'),
          ),
        ],
      ),
    );
  }

  Future<void> _leaveGroupWithDeletion() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      setState(() {
        _isLoading = true;
      });

      final groupRepository = GroupChatRepository();
      final result = await groupRepository.leaveGroupChat(widget.chatId,
          deleteConfirmation: true);

      if (result['success'] == true) {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Group deleted successfully')),
          );
          Navigator.of(context).pop();
        }
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(
              content: Text(result['message'] ?? 'Failed to delete group')),
        );
      }
    } catch (e) {
      debugPrint('Error leaving and deleting group: $e');
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _generateInviteLink() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      setState(() {
        _isLoading = true;
      });

      final groupRepository = GroupChatRepository();
      final inviteLink =
          await groupRepository.generateInviteLink(widget.chatId);

      if (mounted) {
        _showInviteLinkDialog(inviteLink);
      }
    } catch (e) {
      debugPrint('Error generating invite link: $e');
      scaffoldMessenger.showSnackBar(
        SnackBar(
            content: Text(
                'Error generating invite link: ${e.toString().split(':').last.trim()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showInviteLinkDialog(String inviteLink) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Group Invite Link'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Share this link to invite others to the group:'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  inviteLink,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Would implement copy to clipboard functionality here
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link copied to clipboard')),
                );
              },
              child: const Text('Copy'),
            ),
          ],
        );
      },
    );
  }

  // Show the invite members popup
  void _showInviteMembersDialog() {
    if (!widget.isGroupChat) return;

    showDialog(
      context: context,
      builder: (context) => InviteMembersDialog(
        groupId: widget.chatId,
        groupName: widget.chat?.name ?? 'this group',
      ),
    );
  }
}
