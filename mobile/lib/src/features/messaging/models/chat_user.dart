import 'package:flutter/material.dart';

class ChatUser {
  final String id;
  final String name;
  final String? imageUrl;
  final String? location;
  final bool isOnline;
  final DateTime lastActive;
  final String? firstName;
  final String? lastName;
  final String? username;
  final String? email;
  final String? bio;

  ChatUser({
    required this.id,
    required this.name,
    this.imageUrl,
    this.location,
    this.isOnline = false,
    this.firstName,
    this.lastName,
    this.username,
    this.email,
    this.bio,
    DateTime? lastActive,
  }) : lastActive = lastActive ?? DateTime.now();

  // Create a copy of the user with updated properties
  ChatUser copyWith({
    String? id,
    String? name,
    String? imageUrl,
    String? location,
    bool? isOnline,
    DateTime? lastActive,
    String? firstName,
    String? lastName,
    String? username,
    String? email,
    String? bio,
  }) {
    return ChatUser(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      location: location ?? this.location,
      isOnline: isOnline ?? this.isOnline,
      lastActive: lastActive ?? this.lastActive,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      email: email ?? this.email,
      bio: bio ?? this.bio,
    );
  }

  // Create a ChatUser from API data
  factory ChatUser.fromApi(Map<String, dynamic> data) {
    try {
      // Get user ID - try different field names from API
      final id = data['id']?.toString() ?? data['user_id']?.toString() ?? '0';

      // Get username - might be in different formats
      final username = data['username'] as String? ??
          data['user_name'] as String? ??
          'user_$id';

      // Get user's name - try different field combinations
      final firstName = data['first_name'] as String? ?? '';
      final lastName = data['last_name'] as String? ?? '';

      // If we have both first and last name, use them together
      // Otherwise, fall back to profile name, display name, or username
      final fullName = (firstName.isNotEmpty || lastName.isNotEmpty)
          ? '$firstName $lastName'.trim()
          : data['name'] as String? ??
              data['display_name'] as String? ??
              data['profile_name'] as String? ??
              username;

      // Get profile image URL - might be in different fields
      final imageUrl = data['profile_picture_url'] as String? ??
          data['profile_image_url'] as String? ??
          data['avatar'] as String? ??
          data['image_url'] as String? ??
          'https://picsum.photos/640/480?random=$id';

      // Get email if available
      final email = data['email'] as String? ?? '$username@example.com';

      // Extract bio if available
      final bio = data['bio'] as String?;

      // Check if user is online
      final isOnline = data['is_online'] as bool? ?? false;

      return ChatUser(
        id: id,
        name: fullName,
        username: username,
        imageUrl: imageUrl,
        email: email,
        isOnline: isOnline,
        bio: bio,
      );
    } catch (e) {
      debugPrint('Error parsing ChatUser from API data: $e');
      debugPrint('Raw data: $data');

      // Return a placeholder user
      return ChatUser(
        id: data['id']?.toString() ?? '0',
        name: 'Unknown User',
        username: 'unknown',
        imageUrl: 'https://picsum.photos/640/480?random=0',
      );
    }
  }
}
