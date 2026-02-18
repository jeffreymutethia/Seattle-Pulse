import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import '../models/chat.dart';
import '../models/chat_user.dart';
import '../providers/chat_provider.dart';
import '../repositories/group_chat_repository.dart';
import '../widgets/avatar.dart';
import 'add_member_screen.dart';
import '../providers/user_provider.dart';
import '../repositories/user_repository.dart';

class GroupInfoScreen extends ConsumerStatefulWidget {
  final Chat chat;

  const GroupInfoScreen({
    super.key,
    required this.chat,
  });

  @override
  ConsumerState<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends ConsumerState<GroupInfoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoading = false;
  List<ChatUser> _members = [];
  bool _showAdminsOnly = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadGroupMembers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGroupMembers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final groupRepository = GroupChatRepository();
      final members = await groupRepository.getGroupMembers(widget.chat.id);
      setState(() {
        _members = members;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading group members: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load members: $e')),
        );
      }
    }
  }

  bool _isCurrentUserAdmin() {
    final currentUserId = ref.read(currentUserIdProvider);
    return widget.chat.isAdmin(currentUserId) ||
        widget.chat.createdBy?.id == currentUserId;
  }

  bool _isUserAdmin(ChatUser user) {
    return widget.chat.adminIds?.contains(user.id) ??
        false || widget.chat.createdBy?.id == user.id;
  }

  Future<void> _removeMember(ChatUser user) async {
    final currentUserId = ref.read(currentUserIdProvider);

    if (user.id == currentUserId) {
      // Cannot remove yourself
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('You cannot remove yourself. Use Leave Group instead.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final groupRepository = GroupChatRepository();
      final success = await groupRepository.removeMemberFromGroup(
        widget.chat.id,
        user.id,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${user.name} has been removed from the group')),
        );

        // Reload members
        _loadGroupMembers();
      }
    } catch (e) {
      debugPrint('Error removing member: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove member: $e')),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleAdminStatus(ChatUser user) async {
    final isAdmin = _isUserAdmin(user);

    setState(() {
      _isLoading = true;
    });

    try {
      final groupRepository = GroupChatRepository();
      final success = await groupRepository.assignAdminRole(
        widget.chat.id,
        user.id,
        !isAdmin, // Toggle the current status
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAdmin
                ? '${user.name} is no longer an admin'
                : '${user.name} is now an admin'),
          ),
        );

        // Reload members
        _loadGroupMembers();
      }
    } catch (e) {
      debugPrint('Error updating admin status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update admin status: $e')),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(currentUserIdProvider);
    final isAdmin = _isCurrentUserAdmin();

    // Filter members if showing admins only
    final displayedMembers = _showAdminsOnly
        ? _members.where((member) => _isUserAdmin(member)).toList()
        : _members;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chat.name),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: () {
                _showAddMemberScreen();
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Group info card
                _buildGroupInfoCard(),

                // Filter tabs
                Container(
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: TabBar(
                          controller: _tabController,
                          tabs: const [
                            Tab(text: 'All Members'),
                            Tab(text: 'Admins'),
                          ],
                          onTap: (index) {
                            setState(() {
                              _showAdminsOnly = index == 1;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Members list
                Expanded(
                  child: displayedMembers.isEmpty
                      ? const Center(
                          child: Text('No members in this category'),
                        )
                      : ListView.builder(
                          itemCount: displayedMembers.length,
                          itemBuilder: (context, index) {
                            final member = displayedMembers[index];
                            final isCurrentUser = member.id == currentUserId;
                            final isMemberAdmin = _isUserAdmin(member);

                            return ListTile(
                              leading: Avatar(
                                imageUrl: member.imageUrl,
                                size: 40,
                                isOnline: member.isOnline,
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    isCurrentUser
                                        ? '${member.name} (You)'
                                        : member.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (isMemberAdmin) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[100],
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        'Admin',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              trailing: isAdmin && !isCurrentUser
                                  ? PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert),
                                      onSelected: (action) {
                                        if (action == 'remove') {
                                          _showRemoveMemberDialog(member);
                                        } else if (action == 'admin') {
                                          _toggleAdminStatus(member);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        PopupMenuItem(
                                          value: 'admin',
                                          child: Text(
                                            isMemberAdmin
                                                ? 'Remove admin status'
                                                : 'Make admin',
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'remove',
                                          child: Text('Remove from group'),
                                        ),
                                      ],
                                    )
                                  : null,
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildGroupInfoCard() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: widget.chat.imageUrl != null
                ? NetworkImage(widget.chat.imageUrl!)
                : null,
            child: widget.chat.imageUrl == null
                ? Text(
                    widget.chat.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(fontSize: 32),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            widget.chat.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_members.length} Members',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              _showGenerateInviteLinkDialog();
            },
            icon: const Icon(Icons.link),
            label: const Text('Generate Invite Link'),
          ),
          const SizedBox(height: 8),
          const Divider(),
        ],
      ),
    );
  }

  Future<void> _showGenerateInviteLinkDialog() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final groupRepository = GroupChatRepository();
      final inviteLink =
          await groupRepository.generateInviteLink(widget.chat.id);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Group Invite Link'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Share this link to invite others:'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(inviteLink),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('Error generating invite link: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate invite link: $e')),
        );
      }
    }
  }

  void _showRemoveMemberDialog(ChatUser member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text(
            'Are you sure you want to remove ${member.name} from the group?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _removeMember(member);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showAddMemberScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddGroupMemberScreen(groupId: widget.chat.id),
      ),
    );
  }
}

// New screen for adding members with search
class AddGroupMemberScreen extends ConsumerStatefulWidget {
  final String groupId;

  const AddGroupMemberScreen({
    Key? key,
    required this.groupId,
  }) : super(key: key);

  @override
  ConsumerState<AddGroupMemberScreen> createState() =>
      _AddGroupMemberScreenState();
}

class _AddGroupMemberScreenState extends ConsumerState<AddGroupMemberScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadInitialUsers();

    // Add listener for search input
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    // Clear selected users when leaving screen
    ref.read(selectedUsersProvider.notifier).clearAll();
    super.dispose();
  }

  // Load initial set of users
  void _loadInitialUsers() {
    // Get the loading controller
    final loadingController = ref.read(searchLoadingProvider.notifier);

    // Perform initial search with empty query
    ref
        .read(userSearchResultsProvider.notifier)
        .searchUsers('', loadingController: loadingController);
  }

  // Handle search input changes with debounce
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      // Get the current search text
      final query = _searchController.text.trim();

      // Update the search query provider
      ref.read(searchQueryProvider.notifier).state = query;

      // Get the loading controller
      final loadingController = ref.read(searchLoadingProvider.notifier);

      // Perform search
      ref
          .read(userSearchResultsProvider.notifier)
          .searchUsers(query, loadingController: loadingController);
    });
  }

  // Add selected members to the group
  Future<void> _addSelectedMembers() async {
    final selectedUsers = ref.read(selectedUsersProvider);
    if (selectedUsers.isEmpty) {
      return;
    }

    final groupRepository = ref.read(Provider((ref) => GroupChatRepository()));
    bool anySuccess = false;
    int failCount = 0;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Add each user to the group
    for (final user in selectedUsers) {
      try {
        final success =
            await groupRepository.addMemberToGroup(widget.groupId, user.id);
        if (success) {
          anySuccess = true;
        } else {
          failCount++;
        }
      } catch (e) {
        debugPrint('Error adding user ${user.id} to group: $e');
        failCount++;
      }
    }

    // Close loading dialog
    if (mounted) Navigator.of(context).pop();

    // Show result message
    if (mounted) {
      if (anySuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failCount > 0
                ? 'Added some members successfully, but failed to add $failCount members'
                : 'Added ${selectedUsers.length} members successfully'),
          ),
        );
        // Go back to group info screen
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add members to group')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the search results
    final searchResults = ref.watch(userSearchResultsProvider);

    // Watch the loading state
    final isLoading = ref.watch(searchLoadingProvider);

    // Watch selected users
    final selectedUsers = ref.watch(selectedUsersProvider);
    final selectedUsersCount = selectedUsers.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Members'),
        actions: [
          if (selectedUsersCount > 0)
            TextButton.icon(
              onPressed: _addSelectedMembers,
              icon: const Icon(Icons.check),
              label: Text('Add ($selectedUsersCount)'),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            )
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          // Trigger a new search with empty query
                          _onSearchChanged();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
          ),

          // Selected count
          if (selectedUsersCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Text(
                    'Selected: $selectedUsersCount ${selectedUsersCount == 1 ? 'user' : 'users'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      ref.read(selectedUsersProvider.notifier).clearAll();
                    },
                    child: const Text('Clear All'),
                  ),
                ],
              ),
            ),

          // Loading indicator or results
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : searchResults.isEmpty
                    ? const Center(child: Text('No users found'))
                    : ListView.builder(
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) {
                          final user = searchResults[index];
                          final isSelected = ref
                              .read(selectedUsersProvider.notifier)
                              .isSelected(user.id);

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage:
                                  NetworkImage(user.imageUrl ?? ''),
                              child: user.imageUrl == null
                                  ? Text(
                                      user.name.isNotEmpty ? user.name[0] : '?')
                                  : null,
                            ),
                            title: Text(user.name),
                            subtitle: user.username != null
                                ? Text('@${user.username}')
                                : (user.bio != null ? Text(user.bio!) : null),
                            trailing: Checkbox(
                              value: isSelected,
                              onChanged: (_) {
                                ref
                                    .read(selectedUsersProvider.notifier)
                                    .toggleUser(user);
                              },
                            ),
                            onTap: () {
                              ref
                                  .read(selectedUsersProvider.notifier)
                                  .toggleUser(user);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
