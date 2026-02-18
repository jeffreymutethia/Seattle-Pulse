import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat.dart';
import '../providers/chat_provider.dart';
import '../repositories/group_chat_repository.dart';
import '../widgets/chat_list_item.dart';
import 'new_message_screen.dart';
import 'chat_screen.dart';
import 'create_group_screen.dart';

// Provider for caching group chats
final groupChatsProvider = StateProvider<List<Chat>>((ref) => []);
final groupChatsLoadingProvider = StateProvider<bool>((ref) => false);
final groupChatsLastLoadedProvider = StateProvider<DateTime?>((ref) => null);

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Ensure chats are loaded
    Future.microtask(() {
      final state = ref.read(chatStateProvider);
      if (state == ChatFetchState.initial) {
        ref.read(chatsProvider.notifier).fetchChats();
      }

      // Load group chats if needed or if it's been more than 5 minutes
      _loadGroupChatsIfNeeded();
    });

    // Listen to tab changes
    _tabController.addListener(() {
      if (_tabController.index == 1) {
        _loadGroupChatsIfNeeded();
      }
    });
  }

  Future<void> _loadGroupChatsIfNeeded() async {
    // Check if we need to reload
    final groupChats = ref.read(groupChatsProvider);
    final isLoading = ref.read(groupChatsLoadingProvider);
    final lastLoaded = ref.read(groupChatsLastLoadedProvider);

    // If never loaded or it's been more than 5 minutes, reload
    final needsReload = groupChats.isEmpty ||
        lastLoaded == null ||
        DateTime.now().difference(lastLoaded).inMinutes > 5;

    if (needsReload && !isLoading) {
      await _loadGroupChats();
    }
  }

  Future<void> _loadGroupChats() async {
    ref.read(groupChatsLoadingProvider.notifier).state = true;

    try {
      final groupRepository = GroupChatRepository();
      final groups = await groupRepository.getUserGroups();

      // Update the providers
      ref.read(groupChatsProvider.notifier).state = groups;
      ref.read(groupChatsLastLoadedProvider.notifier).state = DateTime.now();
    } catch (e) {
      debugPrint('Error loading group chats: $e');
    } finally {
      ref.read(groupChatsLoadingProvider.notifier).state = false;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get chats from provider
    final chats = ref.watch(chatsProvider);
    final chatState = ref.watch(chatStateProvider);
    final chatError = ref.watch(chatErrorProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showNewMessageOptions(context);
            },
          ),
        ],
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Direct Messages'),
            Tab(text: 'Groups'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Direct Messages Tab
          _buildDirectMessagesTab(chats, chatState, chatError),

          // Group Chats Tab
          _buildGroupChatsTab(),
        ],
      ),
    );
  }

  Widget _buildDirectMessagesTab(
      List<Chat> chats, ChatFetchState chatState, String? chatError) {
    // Filter to show only direct chats
    final directChats = chats.where((chat) => !chat.isGroupChat).toList();

    return _buildChatList(
      directChats,
      chatState,
      chatError,
      emptyMessage: 'No direct messages yet',
    );
  }

  Widget _buildGroupChatsTab() {
    final groupChats = ref.watch(groupChatsProvider);
    final isLoading = ref.watch(groupChatsLoadingProvider);

    if (isLoading && groupChats.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (groupChats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No group chats yet'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _navigateToCreateGroup();
              },
              child: const Text('Create a group'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadGroupChats,
      child: ListView.builder(
        itemCount: groupChats.length,
        itemBuilder: (context, index) {
          final chat = groupChats[index];
          return ChatListItem(
            key: ValueKey(chat.id),
            chat: chat,
            onTap: () => _navigateToChat(chat),
          );
        },
      ),
    );
  }

  Widget _buildChatList(
      List<Chat> chats, ChatFetchState chatState, String? chatError,
      {required String emptyMessage}) {
    if (chatState == ChatFetchState.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (chatState == ChatFetchState.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: ${chatError ?? 'Unknown error'}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(chatsProvider.notifier).fetchChats();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (chats.isEmpty) {
      return Center(child: Text(emptyMessage));
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(chatsProvider.notifier).fetchChats();
      },
      child: ListView.builder(
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final chat = chats[index];
          return ChatListItem(
            key: ValueKey(chat.id),
            chat: chat,
            onTap: () => _navigateToChat(chat),
          );
        },
      ),
    );
  }

  void _navigateToChat(Chat chat) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatId: chat.id,
          chat: chat,
          isGroupChat: chat.isGroupChat,
        ),
      ),
    ).then((_) {
      // Refresh data only if needed when returning from chat screen
      if (chat.isGroupChat) {
        // Don't reload immediately, just mark the last load time as older
        // This will trigger a reload next time we view the tab
        final lastLoaded =
            ref.read(groupChatsLastLoadedProvider) ?? DateTime.now();
        ref.read(groupChatsLastLoadedProvider.notifier).state = lastLoaded
            .subtract(const Duration(minutes: 6)); // Force reload next time
      }
    });
  }

  void _navigateToCreateGroup() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateGroupScreen(),
      ),
    ).then((newGroup) {
      if (newGroup != null) {
        // If we created a new group, reload the group list
        _loadGroupChats();
      }
    });
  }

  void _showNewMessageOptions(BuildContext context) {
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
                leading: const Icon(Icons.chat),
                title: const Text('New Message'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NewMessageScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.group_add),
                title: const Text('Create Group'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToCreateGroup();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
