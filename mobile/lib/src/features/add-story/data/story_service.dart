// story_repository.dart

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:seattle_pulse_mobile/src/core/api/api_client.dart';
import 'package:seattle_pulse_mobile/src/features/add-story/data/aws_upload_service.dart';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';

class StoryRepository {
  final ApiClient api;
  late final AwsUploadService _awsUploadService;

  // Store the uploaded thumbnail URL
  String? _uploadedThumbnailUrl;

  // Getter for the uploaded thumbnail URL
  String? get uploadedThumbnailUrl => _uploadedThumbnailUrl;

  StoryRepository(this.api) {
    _awsUploadService = AwsUploadService(api);
  }

  /// `body` is required as per your API documentation.
  /// `location`, `latitude`, `longitude`, and `thumbnail` are optional.
  Future<Response> addStory({
    String? body,
    String? location,
    double? latitude,
    double? longitude,
    File? thumbnail,
  }) async {
    String? thumbnailUrl;

    // If thumbnail is provided, upload it to AWS S3
    if (thumbnail != null) {
      thumbnailUrl = await _uploadThumbnail(thumbnail);
      // Store the thumbnail URL for later use
      _uploadedThumbnailUrl = thumbnailUrl;
    } else if (_uploadedThumbnailUrl != null) {
      // Use the previously uploaded thumbnail URL if available
      thumbnailUrl = _uploadedThumbnailUrl;
    }

    // We need multipart/form-data
    final formData = FormData();

    // Add body if provided
    if (body != null && body.isNotEmpty) {
      formData.fields.add(MapEntry('body', body));
    }

    // Either location or lat/long can be sent
    if (location != null && location.isNotEmpty) {
      formData.fields.add(MapEntry('location', location));
    }
    if (latitude != null && longitude != null) {
      formData.fields.add(MapEntry('latitude', latitude.toString()));
      formData.fields.add(MapEntry('longitude', longitude.toString()));
    }

    // Add the thumbnail URL instead of the file
    if (thumbnailUrl != null) {
      formData.fields.add(MapEntry('thumbnail_url', thumbnailUrl));
    }

    final response = await api.post('/content/add_story', data: formData);
    return response;
  }

  /// Helper function to upload a thumbnail to AWS S3
  Future<String> _uploadThumbnail(File thumbnail) async {
    try {
      // Get file details
      final fileName = path.basename(thumbnail.path);
      final fileSize = await thumbnail.length();
      final mimeType = lookupMimeType(thumbnail.path) ?? 'image/jpeg';

      // Step 1: Prepare the upload
      final prepareResult = await _awsUploadService.prepareUpload(
        filename: fileName,
        contentType: mimeType,
        fileSize: fileSize,
      );

      // Save the thumbnail URL from the prepare step as fallback
      final fallbackThumbnailUrl =
          prepareResult['presigned_url'] as String? ?? '';

      // Step 2: Upload the file to S3
      final uploadSuccess = await _awsUploadService.uploadFile(
        presignedUrl: prepareResult['presigned_url'],
        file: thumbnail,
        contentType: mimeType,
      );

      if (!uploadSuccess) {
        throw Exception('Failed to upload thumbnail to S3');
      }

      // Step 3: Complete the upload
      final completeResult = await _awsUploadService.completeUpload(
        uploadKey: prepareResult['upload_key'],
      );

      // Return the thumbnail URL or fallback to the one from prepare step if needed
      if (completeResult.containsKey('thumbnail_url') &&
          completeResult['thumbnail_url'] != null) {
        return completeResult['thumbnail_url'];
      } else if (prepareResult.containsKey('thumbnail_url') &&
          prepareResult['thumbnail_url'] != null) {
        return prepareResult['thumbnail_url'];
      } else {
        // If we can't get a thumbnail URL from the response, construct one based on the upload key
        // This is a fallback solution - ideally the server should return the correct URL
        return fallbackThumbnailUrl;
      }
    } catch (e) {
      throw Exception('Error uploading thumbnail: $e');
    }
  }

  /// Public method to just upload an image without creating a story
  Future<String> uploadImageOnly(File image) async {
    final thumbnailUrl = await _uploadThumbnail(image);
    // Store the thumbnail URL for later use when creating the story
    _uploadedThumbnailUrl = thumbnailUrl;
    return thumbnailUrl;
  }

  // Clear the stored thumbnail URL (can be called when needed)
  void clearUploadedThumbnailUrl() {
    _uploadedThumbnailUrl = null;
  }
}
