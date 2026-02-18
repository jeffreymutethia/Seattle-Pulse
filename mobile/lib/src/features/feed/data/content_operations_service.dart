import 'package:seattle_pulse_mobile/src/core/api/api_client.dart';
import 'package:seattle_pulse_mobile/src/features/feed/models/content_operation_model.dart';

class ContentOperationsService {
  final ApiClient _apiClient;

  ContentOperationsService(this._apiClient);

  /// Delete a story by its content ID
  /// Returns a [ContentOperationResponse] with the operation result
  Future<ContentOperationResponse> deleteStory(int contentId) async {
    try {
      final response =
          await _apiClient.delete('/content/delete_story/$contentId');
      return ContentOperationResponse.fromJson(response.data);
    } catch (e) {
      return ContentOperationResponse(
        status: 'error',
        message: 'Failed to delete content: ${e.toString()}',
      );
    }
  }

  /// Report inappropriate content
  /// Takes a [ReportContentRequest] containing the contentId, reason, and optionally customReason
  Future<ContentOperationResponse> reportContent(
      ReportContentRequest request) async {
    try {
      final response = await _apiClient.post(
        '/content/report_content',
        data: request.toJson(),
      );
      return ContentOperationResponse.fromJson(response.data);
    } catch (e) {
      return ContentOperationResponse(
        status: 'error',
        message: 'Failed to report content: ${e.toString()}',
      );
    }
  }

  /// Hide content from user's feed
  /// Takes a content ID to hide
  Future<ContentOperationResponse> hideContent(int contentId) async {
    try {
      final response =
          await _apiClient.post('/content/hide_content/$contentId');
      return ContentOperationResponse.fromJson(response.data);
    } catch (e) {
      return ContentOperationResponse(
        status: 'error',
        message: 'Failed to hide content: ${e.toString()}',
      );
    }
  }
}
