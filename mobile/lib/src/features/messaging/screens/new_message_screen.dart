import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_user.dart';
import '../providers/chat_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/avatar.dart';
import 'chat_screen.dart';

class NewMessageScreen extends ConsumerStatefulWidget {
  const NewMessageScreen({super.key});

  @override
  ConsumerState<NewMessageScreen> createState() => _NewMessageScreenState();
}

class _NewMessageScreenState extends ConsumerState<NewMessageScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isStartingChat = false;
  bool _isSending = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use the following users providers
    final filteredUsers = ref.watch(filteredUsersProvider);
    final fetchState = ref.watch(userFetchStateProvider);
    final isLoading = fetchState == UserFetchState.loading;

    // Watch the chat state for loading indicator
    final chatState = ref.watch(chatStateProvider);
    _isStartingChat = chatState == ChatFetchState.loading;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'New Message',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey[300],
            height: 1.0,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search box
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search...',
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
              onChanged: (value) {
                ref.read(userSearchQueryProvider.notifier).state = value;
                if (value.isNotEmpty) {
                  // Search with API
                  ref.read(followingUsersProvider.notifier).searchUsers(value);
                }
              },
            ),
          ),

          // Loading indicator
          if (_isStartingChat || isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),

          // Error message
          if (fetchState == UserFetchState.error)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    ref.watch(userFetchErrorProvider) ?? 'Failed to load users',
                    style: const TextStyle(color: Colors.red),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      ref
                          .read(followingUsersProvider.notifier)
                          .fetchFollowingUsers();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),

          // Users list
          Expanded(
            child: filteredUsers.isEmpty && !isLoading
                ? const Center(child: Text('No users found'))
                : ListView.builder(
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      return _buildUserItem(user);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserItem(ChatUser user) {
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
          : user.bio != null
              ? Text(
                  user.bio!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12.0,
                  ),
                )
              : user.username != null
                  ? Text(
                      '@${user.username}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12.0,
                      ),
                    )
                  : null,
      onTap: _isStartingChat ? null : () => _startChatWithUser(user),
    );
  }

  Future<void> _startChatWithUser(ChatUser user) async {
    // Start a chat with the selected user
    try {
      setState(() {
        _isSending = true;
      });

      // Show starting chat indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 2,
              ),
              const SizedBox(width: 16),
              Text('Starting chat with ${user.name}...'),
            ],
          ),
          duration: const Duration(
              seconds: 30), // Long duration, will be dismissed on success
        ),
      );

      debugPrint('Starting chat with user: ${user.id}, ${user.name}');
      final chat = await ref.read(chatsProvider.notifier).startChat(user);

      // Clear the loading snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (chat != null && mounted) {
        debugPrint('Chat created successfully: ${chat.id}');
        debugPrint(
            'Chat details: ${chat.name}, participants: ${chat.participants.length}');

        // Navigate to chat screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatId: chat.id,
              chat: chat,
            ),
          ),
        );
      } else if (mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to start chat. Please try again.'),
          ),
        );
      }
    } catch (e) {
      // Clear any existing snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      debugPrint('Error in _startChatWithUser: $e');
      if (mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }
}
