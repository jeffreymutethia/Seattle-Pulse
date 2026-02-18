import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seattle_pulse_mobile/src/core/api/api_client.dart';
import 'package:seattle_pulse_mobile/src/features/feed/data/content_operations_service.dart';
import 'package:seattle_pulse_mobile/src/features/feed/models/content_operation_model.dart';
import 'package:seattle_pulse_mobile/src/features/feed/providers/content_provider.dart';

// Provider for the ContentOperationsService
final contentOperationsServiceProvider =
    Provider<ContentOperationsService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ContentOperationsService(apiClient);
});

// Provider for handling content operations state
final contentOperationsProvider =
    StateNotifierProvider<ContentOperationsNotifier, ContentOperationsState>(
        (ref) {
  final service = ref.watch(contentOperationsServiceProvider);
  return ContentOperationsNotifier(service, ref);
});

// State for content operations
class ContentOperationsState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  ContentOperationsState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  ContentOperationsState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
  }) {
    return ContentOperationsState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

// Notifier for content operations
class ContentOperationsNotifier extends StateNotifier<ContentOperationsState> {
  final ContentOperationsService _service;
  final Ref _ref;

  ContentOperationsNotifier(this._service, this._ref)
      : super(ContentOperationsState());

  // Clear any messages
  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }

  // Delete a story
  Future<bool> deleteStory(int contentId) async {
    state = state.copyWith(
        isLoading: true, errorMessage: null, successMessage: null);
    try {
      final response = await _service.deleteStory(contentId);

      if (response.status == 'success') {
        // Refresh the content list
        _ref.read(contentNotifierProvider.notifier).fetchFirstPage();

        state = state.copyWith(
          isLoading: false,
          successMessage: response.message,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: response.message,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to delete story: ${e.toString()}',
      );
      return false;
    }
  }

  // Report content
  Future<bool> reportContent(ReportContentRequest request) async {
    state = state.copyWith(
        isLoading: true, errorMessage: null, successMessage: null);
    try {
      final response = await _service.reportContent(request);

      if (response.status == 'success') {
        state = state.copyWith(
          isLoading: false,
          successMessage: response.message,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: response.message,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to report content: ${e.toString()}',
      );
      return false;
    }
  }

  // Hide content
  Future<bool> hideContent(int contentId) async {
    state = state.copyWith(
        isLoading: true, errorMessage: null, successMessage: null);
    try {
      final response = await _service.hideContent(contentId);

      if (response.status == 'success') {
        // Refresh the content list
        _ref.read(contentNotifierProvider.notifier).fetchFirstPage();

        state = state.copyWith(
          isLoading: false,
          successMessage: response.message,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: response.message,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to hide content: ${e.toString()}',
      );
      return false;
    }
  }
}
