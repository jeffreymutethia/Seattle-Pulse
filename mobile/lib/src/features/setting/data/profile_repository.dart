// lib/features/profile/data/profile_repository.dart

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:seattle_pulse_mobile/src/core/api/api_client.dart';
import 'package:seattle_pulse_mobile/src/features/auth/data/models/user_model.dart';

class ProfileRepository {
  final ApiClient _apiClient;
  ProfileRepository(this._apiClient);

  /// PATCH /profile/edit_profile (multipart/form-data)
  Future<UserModel> editProfile({
    String? firstName,
    String? lastName,
    String? username,
    String? email,
    String? bio,
    String? location,
    File? profilePicture,
  }) async {
    final formData = FormData();

    if (firstName != null) formData.fields.add(MapEntry('first_name', firstName));
    if (lastName  != null) formData.fields.add(MapEntry('last_name', lastName));
    if (username  != null) formData.fields.add(MapEntry('username', username));
    if (email     != null) formData.fields.add(MapEntry('email', email));
    if (bio       != null) formData.fields.add(MapEntry('bio', bio));
    if (location  != null) formData.fields.add(MapEntry('location', location));

    if (profilePicture != null) {
      final name = profilePicture.path.split('/').last;
      formData.files.add(
        MapEntry(
          'profile_picture',
          await MultipartFile.fromFile(profilePicture.path, filename: name),
        ),
      );
    }

    final resp = await _apiClient.dio.patch(
      '/profile/edit_profile',
      data: formData,
    );
    final userJson = resp.data['user'] as Map<String, dynamic>;
    return UserModel.fromJson(userJson);
  }

  /// PATCH /profile/toggle-home-location → returns new boolean
  Future<bool> toggleHomeLocation(bool show) async {
    final resp = await _apiClient.dio.patch(
      '/profile/toggle-home-location',
      data: { 'show_home_location': show },
    );
    // according to docs: resp.data['data']['show_home_location']
    return (resp.data['data']['show_home_location'] as bool);
  }

  /// DELETE /profile/delete_user
  Future<void> deleteUser({
    String? username,
    String? email,
    required String reason,
    String? comments,
  }) async { /* unchanged */ }
}
