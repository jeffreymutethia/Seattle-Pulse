import 'package:flutter/material.dart';
import 'chat_user.dart';

enum MessageType {
  text,
  image,
  voice,
  file,
}

class Message {
  final String id;
  final String senderId;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final MessageType type;
  final ChatUser? sender; // The sender of the message
  final String? chatId; // The chat this message belongs to

  Message({
    required this.id,
    required this.senderId,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.type = MessageType.text,
    this.sender,
    this.chatId,
  });

  // Create a copy of the message with updated properties
  Message copyWith({
    String? id,
    String? senderId,
    String? content,
    DateTime? timestamp,
    bool? isRead,
    MessageType? type,
    ChatUser? sender,
    String? chatId,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      sender: sender ?? this.sender,
      chatId: chatId ?? this.chatId,
    );
  }

  // Create a Message object from API data
  factory Message.fromApi(Map<String, dynamic> data,
      {Map<String, dynamic>? senderData}) {
    try {
      // Add debugging to trace message creation
      debugPrint(
          '📩 Creating Message from API data: sender_id=${data['sender_id']}');

      // Create sender object if sender data is available
      ChatUser? sender;
      if (data['sender'] != null) {
        try {
          sender = ChatUser.fromApi(data['sender'] as Map<String, dynamic>);
        } catch (e) {
          debugPrint('Error parsing sender data from message: $e');
        }
      } else if (senderData != null) {
        try {
          sender = ChatUser.fromApi(senderData);
        } catch (e) {
          debugPrint('Error parsing provided sender data: $e');
        }
      }

      final senderId = data['sender_id']?.toString() ?? '0';
      final messageId = data['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString();
      final chatId = data['chat_id']?.toString() ?? '';
      final content = data['content'] as String? ?? 'No content';

      // For date, try different field names from API
      final createdAt = data['created_at'] ?? data['timestamp'];
      final timestamp = createdAt != null
          ? DateTime.parse(createdAt.toString())
          : DateTime.now();

      // Debug the parsed values
      debugPrint(
          '📩 PARSED: id=$messageId, senderId=$senderId, chatId=$chatId, content=$content');

      return Message(
        id: messageId,
        senderId: senderId,
        content: content,
        timestamp: timestamp,
        isRead:
            true, // API doesn't provide read status in current implementation
        sender: sender,
        chatId: chatId,
      );
    } catch (e) {
      debugPrint('Error creating Message from API data: $e');
      debugPrint('Raw data: $data');
      // Return a fallback message
      return Message(
        id: 'error_${DateTime.now().millisecondsSinceEpoch}',
        senderId: '0',
        content: 'Error parsing message data',
        timestamp: DateTime.now(),
      );
    }
  }
}
