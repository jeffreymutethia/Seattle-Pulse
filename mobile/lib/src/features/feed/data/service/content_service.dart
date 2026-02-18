import 'package:seattle_pulse_mobile/src/core/api/api_client.dart';
import 'package:seattle_pulse_mobile/src/features/feed/data/models/content_model.dart';
import 'package:flutter/foundation.dart';

class ContentService {
  final ApiClient api;

  ContentService(this.api);

  Future<ContentResponse> fetchContent({int page = 1, int? locationId}) async {
    String endpoint = '/content/?page=$page';

    // Add location filter if provided
    if (locationId != null) {
      endpoint += '&location_id=$locationId';
    }

    debugPrint("ContentService: Requesting $endpoint ...");

    final response = await api.get(endpoint);

    debugPrint(
        "ContentService: Response data => ${response.data.toString().substring(0, 100)}...");

    return ContentResponse.fromJson(response.data);
  }
}
