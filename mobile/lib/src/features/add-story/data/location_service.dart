import 'package:dio/dio.dart';
import 'package:seattle_pulse_mobile/src/core/api/api_client.dart';
import 'package:location/location.dart' as loc;

class LocationResult {
  final String locationLabel;
  final double latitude;
  final double longitude;
  final Map<String, dynamic> rawData;

  LocationResult({
    required this.locationLabel,
    required this.latitude,
    required this.longitude,
    required this.rawData,
  });

  factory LocationResult.fromJson(Map<String, dynamic> json) {
    return LocationResult(
      locationLabel: json['location_label'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      rawData: json['raw'] ?? {},
    );
  }
}

class SearchLocationResponse {
  final String query;
  final int page;
  final int limit;
  final List<LocationResult> results;
  final int totalResults;

  SearchLocationResponse({
    required this.query,
    required this.page,
    required this.limit,
    required this.results,
    required this.totalResults,
  });

  factory SearchLocationResponse.fromJson(Map<String, dynamic> json) {
    return SearchLocationResponse(
      query: json['query'],
      page: json['page'],
      limit: json['limit'],
      results: (json['results'] as List)
          .map((item) => LocationResult.fromJson(item))
          .toList(),
      totalResults: json['total_results'],
    );
  }
}

class LocationService {
  final ApiClient api;
  final loc.Location _location = loc.Location();

  LocationService(this.api);

  /// Search for locations using the API
  Future<SearchLocationResponse> searchLocations({
    required String query,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await api.get(
        '/content/search_location_for_upload',
        queryParams: {
          'query': query,
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );

      if (response.statusCode == 200) {
        return SearchLocationResponse.fromJson(response.data);
      } else {
        // Return empty results instead of throwing an exception
        print('Warning: Search returned status code ${response.statusCode}');
        return SearchLocationResponse(
          query: query,
          page: page,
          limit: limit,
          results: [],
          totalResults: 0,
        );
      }
    } catch (e) {
      // Handle 404 "No matching locations found" gracefully
      if (e is DioException && e.response?.statusCode == 404) {
        print('Info: No matching locations found for query "$query"');
        return SearchLocationResponse(
          query: query,
          page: page,
          limit: limit,
          results: [],
          totalResults: 0,
        );
      }

      // Log but don't throw exception
      print('Warning: Error searching locations: $e');
      return SearchLocationResponse(
        query: query,
        page: page,
        limit: limit,
        results: [],
        totalResults: 0,
      );
    }
  }

  /// Get the current location of the device
  Future<LocationResult?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          print('Location services not enabled');
          return null;
        }
      }

      loc.PermissionStatus permissionStatus = await _location.hasPermission();
      if (permissionStatus == loc.PermissionStatus.denied) {
        permissionStatus = await _location.requestPermission();
        if (permissionStatus != loc.PermissionStatus.granted) {
          print('Location permission not granted');
          return null;
        }
      }

      final locationData = await _location.getLocation();

      if (locationData.latitude != null && locationData.longitude != null) {
        // Create basic location result with coordinates
        final basicResult = LocationResult(
          locationLabel: "Current Location",
          latitude: locationData.latitude!,
          longitude: locationData.longitude!,
          rawData: {
            "display_name":
                "Current Location (${locationData.latitude!.toStringAsFixed(4)}, ${locationData.longitude!.toStringAsFixed(4)})"
          },
        );

        try {
          // Try to perform reverse geocoding to get the location name
          // We'll use a simplified approach since we don't have a direct reverse geocoding endpoint

          // Make a search with the coordinates as a query to find nearby locations
          final response = await searchLocations(
            query:
                "${locationData.latitude!.toStringAsFixed(6)},${locationData.longitude!.toStringAsFixed(6)}",
            limit: 1,
          );

          if (response.results.isNotEmpty) {
            // Use the first result from the search
            final result = response.results.first;

            return LocationResult(
              locationLabel: result.locationLabel,
              latitude: locationData.latitude!,
              longitude: locationData.longitude!,
              rawData: result.rawData,
            );
          } else {
            // If no results, return the basic result
            return basicResult;
          }
        } catch (e) {
          print('Reverse geocoding warning: $e');
          // If reverse geocoding fails, just return the basic result
          return basicResult;
        }
      } else {
        print('No location data available');
        return null;
      }
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }
}
