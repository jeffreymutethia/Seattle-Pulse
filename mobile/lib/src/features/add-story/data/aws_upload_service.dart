import 'dart:io';
import 'package:dio/dio.dart';
import 'package:seattle_pulse_mobile/src/core/api/api_client.dart';
import 'package:http/http.dart' as http;

class AwsUploadService {
  final ApiClient api;

  AwsUploadService(this.api);

  /// Prepares the upload by getting a pre-signed URL from the backend
  /// Returns a map containing the presigned_url, upload_key, and bucket_name
  Future<Map<String, dynamic>> prepareUpload({
    required String filename,
    required String contentType,
    required int fileSize,
  }) async {
    try {
      final response = await api.post('/upload/prepare', data: {
        'filename': filename,
        'content_type': contentType,
        'file_size': fileSize,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Create result with required fields
        final result = {
          'presigned_url': response.data['presigned_url'],
          'upload_key': response.data['final_upload_key'],
        };

        // Add bucket_name if available
        if (response.data['s3_bucket'] != null) {
          result['bucket_name'] = response.data['s3_bucket'];
        } else if (response.data['bucket_name'] != null) {
          result['bucket_name'] = response.data['bucket_name'];
        }

        // Add thumbnail_url if available
        if (response.data['thumbnail_url'] != null) {
          result['thumbnail_url'] = response.data['thumbnail_url'];
        }

        return result;
      } else {
        throw Exception('Failed to prepare upload: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error preparing upload: $e');
    }
  }

  /// Uploads the file to S3 using the presigned URL
  Future<bool> uploadFile({
    required String presignedUrl,
    required File file,
    required String contentType,
  }) async {
    try {
      // Using http package for direct PUT to S3
      final fileBytes = await file.readAsBytes();
      final response = await http.put(
        Uri.parse(presignedUrl),
        body: fileBytes,
        headers: {
          'Content-Type': contentType,
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to upload file: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error uploading file: $e');
    }
  }

  /// Completes the upload process by notifying the backend
  Future<Map<String, dynamic>> completeUpload({
    required String uploadKey,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'upload_key': uploadKey,
      };

      if (metadata != null) {
        requestData['metadata'] = metadata;
      }

      final response = await api.post('/upload/complete', data: requestData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Return data with safe handling of optional fields
        final result = {
          'success': response.data['success'] ?? true,
          'message': response.data['message'] ?? 'Upload completed.',
        };

        // Safely extract content_id and thumbnail_url if they exist
        if (response.data['data'] != null) {
          if (response.data['data']['content_id'] != null) {
            result['content_id'] = response.data['data']['content_id'];
          }
          if (response.data['data']['thumbnail_url'] != null) {
            result['thumbnail_url'] = response.data['data']['thumbnail_url'];
          }
        }

        // If thumbnail_url is not in the response but we have a presigned URL from prepare step
        // we can use that (passed from the prepare step)
        if (!result.containsKey('thumbnail_url') &&
            response.data['thumbnail_url'] != null) {
          result['thumbnail_url'] = response.data['thumbnail_url'];
        }

        return result;
      } else {
        throw Exception('Failed to complete upload: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error completing upload: $e');
    }
  }
}
