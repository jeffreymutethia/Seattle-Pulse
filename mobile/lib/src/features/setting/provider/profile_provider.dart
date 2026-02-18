// lib/features/profile/provider/profile_provider.dart

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seattle_pulse_mobile/src/core/api/api_client.dart';
import 'package:seattle_pulse_mobile/src/features/auth/data/models/user_model.dart';
import 'package:seattle_pulse_mobile/src/features/setting/data/profile_repository.dart';

/// 1) Make your ApiClient available
final apiClientProvider = Provider<ApiClient>((_) => ApiClient());

/// 2) Provide the repository
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.read(apiClientProvider));
});

/// 3) Params class for editProfile
class EditProfileParams {
  final String? username;
  final String? email;
  final String? bio;
  final String? location;
  final File? profilePicture;

  EditProfileParams({
    this.username,
    this.email,
    this.bio,
    this.location,
    this.profilePicture,
  });
}

/// 4) Provider to call editProfile
final editProfileProvider = FutureProvider.family<UserModel, EditProfileParams>(
  (ref, params) async {
    final repo = ref.read(profileRepositoryProvider);
    return repo.editProfile(
      username:        params.username,
      email:           params.email,
      bio:             params.bio,
      location:        params.location,
      profilePicture:  params.profilePicture,
    );
  },
);

/// 5) Params class for deleteUser
class DeleteUserParams {
  final String? username;
  final String? email;
  final String  reason;
  final String? comments;

  DeleteUserParams({
    this.username,
    this.email,
    required this.reason,
    this.comments,
  });
}

/// 6) Provider to call deleteUser
final deleteUserProvider = FutureProvider.family<void, DeleteUserParams>(
  (ref, params) async {
    final repo = ref.read(profileRepositoryProvider);
    await repo.deleteUser(
      username: params.username,
      email:    params.email,
      reason:   params.reason,
      comments: params.comments,
    );
  },
);

/// 7) Provider to toggle home-location visibility
final toggleHomeLocationProvider = FutureProvider.family<void, bool>(
  (ref, show) async {
    final repo = ref.read(profileRepositoryProvider);
    await repo.toggleHomeLocation(show);
  },
);
