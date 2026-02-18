// add_story_notifier.dart

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seattle_pulse_mobile/src/core/api/api_client.dart';
import 'package:seattle_pulse_mobile/src/features/add-story/data/story_service.dart';

/// Represents the various states when adding a story
class AddStoryState {
  final bool isLoading;
  final bool isSuccess;
  final String? errorMessage;
  final bool isUploading;
  final double? uploadProgress;
  final bool isImageUploaded;

  const AddStoryState({
    this.isLoading = false,
    this.isSuccess = false,
    this.errorMessage,
    this.isUploading = false,
    this.uploadProgress,
    this.isImageUploaded = false,
  });

  AddStoryState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? errorMessage,
    bool? isUploading,
    double? uploadProgress,
    bool? isImageUploaded,
  }) {
    return AddStoryState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage,
      isUploading: isUploading ?? this.isUploading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      isImageUploaded: isImageUploaded ?? this.isImageUploaded,
    );
  }
}

/// Notifier that calls the repository to add a story
class AddStoryNotifier extends StateNotifier<AddStoryState> {
  final StoryRepository _storyRepository;

  AddStoryNotifier(this._storyRepository) : super(const AddStoryState());

  /// Upload only the image without posting the story
  Future<void> uploadImage(File image) async {
    try {
      // Start loading state
      state = state.copyWith(
        isUploading: true,
        errorMessage: null,
        uploadProgress: 0.1, // Starting progress
      );

      // Upload the image to S3
      final thumbnailUrl = await _storyRepository.uploadImageOnly(image);

      // Update state to indicate successful upload
      state = state.copyWith(
        isUploading: false,
        uploadProgress: 1.0, // Complete
        isImageUploaded: true,
      );
    } catch (e) {
      // Handle errors
      String errorMessage = e.toString();
      if (errorMessage.contains('Failed to upload thumbnail to S3')) {
        errorMessage = 'Failed to upload image. Please try again.';
      } else if (errorMessage.contains('prepare upload')) {
        errorMessage = 'Could not prepare file upload. Please try again.';
      }

      // Update state with error
      state = state.copyWith(
        isUploading: false,
        errorMessage: errorMessage,
      );
    }
  }

  /// Call this method to add a story.
  Future<void> addStory({
    String? body,
    String? location,
    double? latitude,
    double? longitude,
    File? thumbnail,
  }) async {
    try {
      // Start loading
      state = state.copyWith(
        isLoading: true,
        isSuccess: false,
        errorMessage: null,
        isUploading: thumbnail != null && !state.isImageUploaded,
      );

      // If there's a thumbnail and it's not already uploaded, we'll first upload it
      if (thumbnail != null && !state.isImageUploaded) {
        await uploadImage(thumbnail);
        if (state.errorMessage != null) {
          // If there was an error uploading, don't proceed with posting
          return;
        }
      }

      // Perform the request to create the story
      final response = await _storyRepository.addStory(
        body: body,
        location: location,
        latitude: latitude,
        longitude: longitude,
        // Pass null because the image is already uploaded
        thumbnail: null,
      );

      // If successful, update state
      if (response.statusCode == 200 || response.statusCode == 201) {
        // You could inspect response.data if needed
        state = state.copyWith(
          isLoading: false,
          isSuccess: true,
          isUploading: false,
          uploadProgress: 1.0, // Complete
        );
      } else {
        // If the server responds with an error code
        state = state.copyWith(
          isLoading: false,
          isSuccess: false,
          isUploading: false,
          errorMessage: 'Error: ${response.statusCode}',
        );
      }
    } catch (e) {
      // Handle specific AWS upload errors
      String errorMessage = e.toString();
      if (errorMessage.contains('Failed to upload thumbnail to S3')) {
        errorMessage = 'Failed to upload image. Please try again.';
      } else if (errorMessage.contains('prepare upload')) {
        errorMessage = 'Could not prepare file upload. Please try again.';
      }

      // Catch any other exceptions
      state = state.copyWith(
        isLoading: false,
        isSuccess: false,
        isUploading: false,
        errorMessage: errorMessage,
      );
    }
  }

  /// Clear the upload state (used when navigating to a different page)
  void clearUploadState() {
    state = state.copyWith(
      isLoading: false,
      isSuccess: false,
      errorMessage: null,
      isUploading: false,
      uploadProgress: null,
    );
  }

  /// Reset the error state (used when trying again)
  void resetErrorState() {
    state = state.copyWith(
      errorMessage: null,
    );
  }
}
