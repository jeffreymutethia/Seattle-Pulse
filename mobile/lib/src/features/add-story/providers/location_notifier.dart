import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seattle_pulse_mobile/src/features/add-story/data/location_service.dart';

class LocationSearchState {
  final bool isLoading;
  final bool isSearching;
  final String searchQuery;
  final List<LocationResult> searchResults;
  final LocationResult? selectedLocation;
  final LocationResult? detectedLocation;
  final String? errorMessage;
  final bool isDetectingLocation;

  const LocationSearchState({
    this.isLoading = false,
    this.isSearching = false,
    this.searchQuery = '',
    this.searchResults = const [],
    this.selectedLocation,
    this.detectedLocation,
    this.errorMessage,
    this.isDetectingLocation = false,
  });

  LocationSearchState copyWith({
    bool? isLoading,
    bool? isSearching,
    String? searchQuery,
    List<LocationResult>? searchResults,
    LocationResult? selectedLocation,
    LocationResult? detectedLocation,
    String? errorMessage,
    bool? isDetectingLocation,
  }) {
    return LocationSearchState(
      isLoading: isLoading ?? this.isLoading,
      isSearching: isSearching ?? this.isSearching,
      searchQuery: searchQuery ?? this.searchQuery,
      searchResults: searchResults ?? this.searchResults,
      selectedLocation: selectedLocation ?? this.selectedLocation,
      detectedLocation: detectedLocation ?? this.detectedLocation,
      errorMessage: errorMessage,
      isDetectingLocation: isDetectingLocation ?? this.isDetectingLocation,
    );
  }
}

class LocationSearchNotifier extends StateNotifier<LocationSearchState> {
  final LocationService _locationService;

  LocationSearchNotifier(this._locationService)
      : super(const LocationSearchState());

  /// Detect the current location of the device
  Future<void> detectCurrentLocation() async {
    try {
      state = state.copyWith(
        isDetectingLocation: true,
        errorMessage: null,
      );

      final locationResult = await _locationService.getCurrentLocation();

      if (locationResult != null) {
        state = state.copyWith(
          detectedLocation: locationResult,
          selectedLocation:
              locationResult, // Automatically select the detected location
          isDetectingLocation: false,
        );
      } else {
        // Don't show error message to the user, just set isDetectingLocation to false
        state = state.copyWith(
          isDetectingLocation: false,
          // Don't set an error message here
        );
      }
    } catch (e) {
      // Log the error but don't show it to the user
      print('Error detecting location (not shown to user): $e');
      state = state.copyWith(
        isDetectingLocation: false,
        // Don't set an error message here
      );
    }
  }

  /// Search for locations using the API
  Future<void> searchLocations(String query) async {
    // Skip if the query is empty
    if (query.isEmpty) {
      state = state.copyWith(
        searchResults: [],
        isSearching: false,
      );
      return;
    }

    // Skip if it's the exact same query and we already have results
    if (query == state.searchQuery &&
        state.searchResults.isNotEmpty &&
        !state.isSearching) {
      return;
    }

    try {
      state = state.copyWith(
        isSearching: true,
        searchQuery: query,
        errorMessage: null,
      );

      final response = await _locationService.searchLocations(query: query);

      state = state.copyWith(
        searchResults: response.results,
        isSearching: false,
      );
    } catch (e) {
      // This should not happen anymore since we handle errors in the service,
      // but just in case, handle gracefully
      print('Unexpected error in location search: $e');
      state = state.copyWith(
        isSearching: false,
        searchResults: [], // Clear results on error but don't show error message
      );
    }
  }

  /// Select a location from the search results
  void selectLocation(LocationResult location) {
    state = state.copyWith(
      selectedLocation: location,
      errorMessage: null,
    );
  }

  /// Clear the selected location
  void clearSelectedLocation() {
    state = state.copyWith(
      selectedLocation: null,
    );
  }

  /// Reset the error state
  void resetError() {
    state = state.copyWith(
      errorMessage: null,
    );
  }
}
