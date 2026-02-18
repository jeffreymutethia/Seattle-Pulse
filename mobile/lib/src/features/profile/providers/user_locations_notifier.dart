// user_locations_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seattle_pulse_mobile/src/features/profile/data/models/user_locations_model.dart';
import 'package:seattle_pulse_mobile/src/features/profile/data/service/profile_service.dart';


class UserLocationsState {
  final bool isLoading;
  final String? error;
  final UserLocationsData? locationsData;

  UserLocationsState({this.isLoading = false, this.error, this.locationsData});

  UserLocationsState copyWith({
    bool? isLoading,
    String? error,
    UserLocationsData? locationsData,
  }) {
    return UserLocationsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      locationsData: locationsData ?? this.locationsData,
    );
  }
}

class UserLocationsNotifier extends StateNotifier<UserLocationsState> {
  final UserLocationsService service;
  final String username;

  UserLocationsNotifier(this.service, {required this.username}) : super(UserLocationsState());

  Future<void> fetchUserLocations({int page = 1, int perPage = 10}) async {
    state = state.copyWith(isLoading: true, error: null, locationsData: null);
    try {
      final response = await service.fetchUserLocations(username, page: page, perPage: perPage);
      state = state.copyWith(isLoading: false, locationsData: response.data);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
