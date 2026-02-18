// user_profile_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seattle_pulse_mobile/src/features/profile/data/models/user_profile_model.dart';
import 'package:seattle_pulse_mobile/src/features/profile/data/service/profile_service.dart';


class UserProfileState {
  final bool isLoading;
  final String? error;
  final UserProfileData? profileData;

  UserProfileState({this.isLoading = false, this.error, this.profileData});

  UserProfileState copyWith({
    bool? isLoading,
    String? error,
    UserProfileData? profileData,
  }) {
    return UserProfileState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      profileData: profileData ?? this.profileData,
    );
  }
}

class UserProfileNotifier extends StateNotifier<UserProfileState> {
  final UserProfileService service;
  final String username;

  UserProfileNotifier(this.service, {required this.username}) : super(UserProfileState());

  Future<void> fetchUserProfile() async {
    state = state.copyWith(isLoading: true, error: null, profileData: null);
    try {
      final response = await service.fetchUserProfile(username);
      state = state.copyWith(isLoading: false, profileData: response.data);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
