import 'chat_user.dart';
import 'message.dart';
import 'package:flutter/foundation.dart';

enum ChatType {
  private,
  group,
}

enum GroupRole {
  member,
  admin,
  owner,
}

class Chat {
  final String id;
  final String name;
  final String? imageUrl;
  final List<ChatUser> participants;
  final Message? lastMessage;
  final DateTime createdAt;
  final ChatType type;
  final ChatUser? receiver; // Receiver for direct chats
  final ChatUser? createdBy; // Creator for group chats
  final List<String>? adminIds; // List of admin IDs for group chats

  Chat({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.participants,
    this.lastMessage,
    this.receiver,
    this.createdBy,
    this.adminIds,
    DateTime? createdAt,
    this.type = ChatType.private,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isGroupChat => type == ChatType.group;

  // Check if the user with the given ID is an admin of the group
  bool isAdmin(String userId) {
    if (!isGroupChat) return false;
    return adminIds?.contains(userId) ?? false;
  }

  // Create a copy of the chat with updated properties
  Chat copyWith({
    String? id,
    String? name,
    String? imageUrl,
    List<ChatUser>? participants,
    Message? lastMessage,
    DateTime? createdAt,
    ChatType? type,
    ChatUser? receiver,
    ChatUser? createdBy,
    List<String>? adminIds,
  }) {
    return Chat(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      receiver: receiver ?? this.receiver,
      createdBy: createdBy ?? this.createdBy,
      adminIds: adminIds ?? this.adminIds,
    );
  }

  // Create a Chat object from API data
  factory Chat.fromApi(Map<String, dynamic> data) {
    try {
      // Get basic chat information
      final chatId =
          data['chat_id']?.toString() ?? data['id']?.toString() ?? '0';

      // Ensure we always have a valid participants list
      List<ChatUser> participants = [];

      // Parse latest message if it exists
      Message? lastMessage;
      if (data['latest_message'] != null) {
        try {
          lastMessage =
              Message.fromApi(data['latest_message'] as Map<String, dynamic>);
        } catch (e) {
          debugPrint('Error parsing latest message: $e');
        }
      }

      // Check if this is a group chat
      final bool isGroup = data['type'] == 'group' ||
          data['group_type'] != null ||
          (data['name'] != null && data['receiver'] == null);

      final ChatType chatType = isGroup ? ChatType.group : ChatType.private;

      // Parse participants list if available
      if (data['participants'] != null) {
        try {
          final List<dynamic> participantsData =
              data['participants'] as List<dynamic>;
          participants = participantsData
              .map((p) => ChatUser.fromApi(p as Map<String, dynamic>))
              .toList();
        } catch (e) {
          debugPrint('Error parsing participants list: $e');
        }
      }

      // Parse the receiver (other person in direct chat)
      ChatUser? receiver;
      if (!isGroup && data['receiver'] != null) {
        try {
          receiver = ChatUser.fromApi(data['receiver'] as Map<String, dynamic>);
          if (!participants.any((p) => p.id == receiver!.id)) {
            participants.add(receiver);
          }
          debugPrint(
              'Parsed receiver: id=${receiver.id}, name=${receiver.name}');
        } catch (e) {
          debugPrint('Error parsing receiver data: $e');
          // If we can't parse the receiver, create a placeholder participant
          if (participants.isEmpty) {
            participants.add(ChatUser(
              id: 'unknown',
              name: 'Unknown User',
            ));
          }
        }
      }

      // Parse creator for group chats
      ChatUser? createdBy;
      if (isGroup && data['created_by'] != null) {
        try {
          if (data['created_by'] is Map) {
            createdBy =
                ChatUser.fromApi(data['created_by'] as Map<String, dynamic>);
          } else {
            // If created_by is just an ID
            final createdById = data['created_by'].toString();
            // Try to find this user in participants
            createdBy = participants.firstWhere(
              (p) => p.id == createdById,
              orElse: () => ChatUser(id: createdById, name: 'Unknown Creator'),
            );
          }
        } catch (e) {
          debugPrint('Error parsing group creator: $e');
        }
      }

      // Parse admin IDs for group chats
      List<String>? adminIds;
      if (isGroup && data['admins'] != null) {
        try {
          if (data['admins'] is List) {
            adminIds = (data['admins'] as List)
                .map((a) => a is Map ? a['id'].toString() : a.toString())
                .toList()
                .cast<String>();
          }
        } catch (e) {
          debugPrint('Error parsing admin IDs: $e');
        }
      }

      // Get the last updated timestamp or created_at
      final lastUpdated = data['last_updated'] != null
          ? DateTime.parse(data['last_updated'])
          : data['created_at'] != null
              ? DateTime.parse(data['created_at'])
              : DateTime.now();

      // Create a Chat with the parsed data
      return Chat(
        id: chatId,
        name: isGroup
            ? data['name'] as String? ?? 'Group Chat'
            : receiver?.name ?? 'Unknown Chat',
        imageUrl:
            isGroup ? data['image_url'] as String? ?? null : receiver?.imageUrl,
        participants: participants,
        lastMessage: lastMessage,
        type: chatType,
        createdAt: lastUpdated,
        receiver: isGroup ? null : receiver,
        createdBy: isGroup ? createdBy : null,
        adminIds: isGroup ? adminIds : null,
      );
    } catch (e) {
      debugPrint('Error creating Chat from API data: $e');
      // Return a fallback chat with at least one participant
      return Chat(
        id: 'error_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Error Loading Chat',
        participants: [
          ChatUser(
            id: 'placeholder',
            name: 'Unknown User',
          )
        ],
      );
    }
  }

  // Create a Group Chat object from group API data
  factory Chat.fromGroupApi(Map<String, dynamic> data) {
    try {
      final String groupId = data['id']?.toString() ?? '0';
      final String name = data['name'] as String? ?? 'Group Chat';

      // Parse creator if available
      ChatUser? creator;
      if (data['created_by'] != null) {
        final createdById = data['created_by'].toString();
        creator = ChatUser(id: createdById, name: 'Group Creator');
      }

      return Chat(
        id: groupId,
        name: name,
        participants: [], // Will be populated separately
        type: ChatType.group,
        createdAt: data['created_at'] != null
            ? DateTime.parse(data['created_at'])
            : DateTime.now(),
        createdBy: creator,
      );
    } catch (e) {
      debugPrint('Error creating Chat from group API data: $e');
      return Chat(
        id: 'error_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Error Loading Group',
        type: ChatType.group,
        participants: [],
      );
    }
  }
}
