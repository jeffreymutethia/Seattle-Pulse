class NotificationItem {
  final int id;
  final int userId;
  final String content;
  final bool isRead;
  final DateTime createdAt;
  final int? postId;
  final int? senderId;
  final String type;

  NotificationItem({
    required this.id,
    required this.userId,
    required this.content,
    required this.isRead,
    required this.createdAt,
    this.postId,
    this.senderId,
    required this.type,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'],
      userId: json['user_id'],
      content: json['content'],
      isRead: json['is_read'],
      createdAt: DateTime.parse(json['created_at']),
      postId: json['post_id'] != null ? json['post_id'] as int : null,
      senderId: json['sender_id'] != null ? json['sender_id'] as int : null,
      type: json['type'],
    );
  }
}
