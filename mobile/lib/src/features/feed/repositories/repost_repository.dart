import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:seattle_pulse_mobile/src/core/api/api_client.dart';

class RepostRepository {
  final ApiClient _apiClient;

  RepostRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Repost content
  Future<Map<String, dynamic>> repostContent({
    required int contentId,
    String? thoughts,
  }) async {
    try {
      debugPrint(
          "REPOSITORY: Reposting content $contentId with thoughts: $thoughts");

      final data =
          thoughts != null && thoughts.isNotEmpty ? {'thoughts': thoughts} : {};

      final response = await _apiClient.post(
        '/content/repost/$contentId',
        data: data,
      );

      debugPrint(
          "REPOSITORY: Repost API Response status: ${response.statusCode}");

      // Log full response to help with debugging
      final responseData = response.data;
      debugPrint("REPOSITORY: Repost API Response data: $responseData");

      // Normalize response format
      if (responseData['success'] == 'success' &&
          responseData['status'] == null) {
        responseData['status'] = 'success';
      }

      return responseData;
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Failed to repost content: $e');
    }
  }

  /// Undo a repost
  Future<Map<String, dynamic>> undoRepost({
    required int contentId,
  }) async {
    try {
      debugPrint("REPOSITORY: Undoing repost for content $contentId");

      final response = await _apiClient.post(
        '/content/undo_repost/$contentId',
      );

      debugPrint(
          "REPOSITORY: Undo repost API Response status: ${response.statusCode}");

      // Log full response to help with debugging
      final responseData = response.data;
      debugPrint("REPOSITORY: Undo repost API Response data: $responseData");

      // Normalize response format
      if (responseData['success'] == 'success' &&
          responseData['status'] == null) {
        responseData['status'] = 'success';
      }

      return responseData;
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Failed to undo repost: $e');
    }
  }

  Exception _handleDioException(DioException e) {
    if (e.response != null) {
      final responseData = e.response!.data;
      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('message')) {
        return Exception(responseData['message']);
      }
      return Exception('API Error: ${e.response!.statusCode}');
    }
    return Exception('Network error: ${e.message}');
  }
}
