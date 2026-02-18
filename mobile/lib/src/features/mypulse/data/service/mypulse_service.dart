import 'package:seattle_pulse_mobile/src/core/api/api_client.dart';
import 'package:seattle_pulse_mobile/src/features/feed/data/models/content_model.dart';
import 'package:flutter/foundation.dart';
import 'package:seattle_pulse_mobile/src/features/mypulse/data/models/mypulse_model.dart';

class MypulseService {
  final ApiClient api;

  MypulseService(this.api);

  Future<MypulseResponse> fetchMypulse({int page = 1}) async {
    debugPrint("ContentService: Requesting /content/?page=$page ...");

    final response = await api.get('/feed/mypulse?page=$page');

    debugPrint(
        "ContentService: Response data => ${response.data.toString().substring(0, 100)}...");

    return MypulseResponse.fromJson(response.data);
  }
}
