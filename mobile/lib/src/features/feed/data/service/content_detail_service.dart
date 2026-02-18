import 'package:flutter/foundation.dart';
import 'package:seattle_pulse_mobile/src/core/api/api_client.dart';
import 'package:seattle_pulse_mobile/src/features/feed/data/models/content_detail_model.dart';

class ContentDetailsService {
  final ApiClient api;

  ContentDetailsService(this.api);

  Future<ContentDetailsResponse> fetchContentDetails({
    required String contentType,
    required int contentId,
    int page = 1,
    int perPage = 10,
  }) async {
    debugPrint(
        "ContentDetailsService: Requesting /v1/$contentType/$contentId?page=$page&per_page=$perPage ...");
    final response = await api
        .get('/content/$contentType/$contentId?page=$page&per_page=$perPage');
    print(
        "ContentDetailsService: Response data => ${response.data.toString().substring(0, 100)}...");
    return ContentDetailsResponse.fromJson(response.data);
  }
}
