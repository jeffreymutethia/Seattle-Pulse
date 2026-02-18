import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_user.dart';
import '../repositories/group_chat_repository.dart';

class AddMemberScreen extends ConsumerStatefulWidget {
  final String groupId;

  const AddMemberScreen({
    Key? key,
    required this.groupId,
  }) : super(key: key);

  @override
  ConsumerState<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends ConsumerState<AddMemberScreen> {
  final List<ChatUser> _allUsers = [
    // Mock data - in a real app, fetch from API
    ChatUser(
        id: '1', name: 'John Doe', imageUrl: 'https://i.pravatar.cc/150?img=1'),
    ChatUser(
        id: '2',
        name: 'Jane Smith',
        imageUrl: 'https://i.pravatar.cc/150?img=2'),
    ChatUser(
        id: '3',
        name: 'Bob Johnson',
        imageUrl: 'https://i.pravatar.cc/150?img=3'),
    ChatUser(
        id: '4',
        name: 'Alice Brown',
        imageUrl: 'https://i.pravatar.cc/150?img=4'),
    ChatUser(
        id: '5',
        name: 'Charlie Davis',
        imageUrl: 'https://i.pravatar.cc/150?img=5'),
  ];

  final List<ChatUser> _selectedUsers = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;
  List<ChatUser> _groupMembers = [];

  @override
  void initState() {
    super.initState();
    _loadGroupMembers();
  }

  Future<void> _loadGroupMembers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final groupRepository = GroupChatRepository();
      _groupMembers = await groupRepository.getGroupMembers(widget.groupId);
    } catch (e) {
      debugPrint('Error loading group members: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load group members: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ChatUser> get _filteredUsers {
    // Filter out users who are already in the group
    final availableUsers = _allUsers
        .where((user) => !_groupMembers.any((member) => member.id == user.id))
        .toList();

    if (_searchQuery.isEmpty) {
      return availableUsers;
    }

    return availableUsers
        .where((user) =>
            user.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  Future<void> _addSelectedMembers() async {
    if (_selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one member to add')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final groupRepository = GroupChatRepository();

      for (final user in _selectedUsers) {
        await groupRepository.addMemberToGroup(widget.groupId, user.id);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Added ${_selectedUsers.length} members to the group')),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error adding members: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add members: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Members'),
        actions: [
          if (_selectedUsers.isNotEmpty)
            TextButton.icon(
              onPressed: _isLoading ? null : _addSelectedMembers,
              icon: const Icon(Icons.person_add),
              label: Text('Add (${_selectedUsers.length})'),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Users',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          if (_selectedUsers.isNotEmpty) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selected Users:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedUsers.map((user) {
                      return Chip(
                        avatar: CircleAvatar(
                          backgroundImage: user.imageUrl != null
                              ? NetworkImage(user.imageUrl!)
                              : null,
                          child: user.imageUrl == null
                              ? Text(user.name[0].toUpperCase())
                              : null,
                        ),
                        label: Text(user.name),
                        onDeleted: () {
                          setState(() {
                            _selectedUsers.remove(user);
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const Divider(),
          ],
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? const Center(
                        child: Text('No users available to add'),
                      )
                    : ListView.builder(
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          final isSelected = _selectedUsers.contains(user);

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: user.imageUrl != null
                                  ? NetworkImage(user.imageUrl!)
                                  : null,
                              child: user.imageUrl == null
                                  ? Text(user.name[0].toUpperCase())
                                  : null,
                            ),
                            title: Text(user.name),
                            subtitle:
                                user.email != null ? Text(user.email!) : null,
                            trailing: isSelected
                                ? const Icon(Icons.check_circle,
                                    color: Colors.green)
                                : const Icon(Icons.circle_outlined),
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedUsers.remove(user);
                                } else {
                                  _selectedUsers.add(user);
                                }
                              });
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar: _selectedUsers.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _addSelectedMembers,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : Text('Add ${_selectedUsers.length} Members'),
                ),
              ),
            )
          : null,
    );
  }
}
