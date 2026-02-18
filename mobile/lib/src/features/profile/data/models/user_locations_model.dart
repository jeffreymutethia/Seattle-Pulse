// user_locations_model.dart

class UserLocationsResponse {
  final String success;
  final String message;
  final UserLocationsData data;

  UserLocationsResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory UserLocationsResponse.fromJson(Map<String, dynamic> json) {
    return UserLocationsResponse(
      success: json['success'] ?? '',
      message: json['message'] ?? '',
      data: UserLocationsData.fromJson(json['data']),
    );
  }
}

class UserLocationsData {
  final List<Location> locations;
  final CenterPoint center;

  UserLocationsData({
    required this.locations,
    required this.center,
  });

  factory UserLocationsData.fromJson(Map<String, dynamic> json) {
    return UserLocationsData(
      locations: (json['locations'] as List)
          .map((e) => Location.fromJson(e))
          .toList(),
      center: CenterPoint.fromJson(json['center']),
    );
  }
}

class Location {
  final int contentId;
  final String title;
  final String location;
  final double latitude;
  final double longitude;

  Location({
    required this.contentId,
    required this.title,
    required this.location,
    required this.latitude,
    required this.longitude,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      contentId: json['content_id'] ?? 0,
      title: json['title'] ?? '',
      location: json['location'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class CenterPoint {
  final double latitude;
  final double longitude;

  CenterPoint({
    required this.latitude,
    required this.longitude,
  });

  factory CenterPoint.fromJson(Map<String, dynamic> json) {
    return CenterPoint(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
