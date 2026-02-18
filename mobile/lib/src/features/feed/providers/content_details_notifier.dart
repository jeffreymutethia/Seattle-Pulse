import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seattle_pulse_mobile/src/features/feed/data/models/content_detail_model.dart';
import 'package:seattle_pulse_mobile/src/features/feed/data/service/content_detail_service.dart';
import 'package:seattle_pulse_mobile/src/features/feed/providers/content_details_state.dart';

class ContentDetailsNotifier extends StateNotifier<ContentDetailsState> {
  final ContentDetailsService _contentDetailsService;
  final String contentType;
  final int contentId;

  /// No fetch is triggered here.
  /// This avoids repeated calls if the widget re-creates the provider.
  ContentDetailsNotifier(
    this._contentDetailsService, {
    required this.contentType,
    required this.contentId,
  }) : super(ContentDetailsState());

  /// Fetch the initial content details (including comments)
  Future<void> fetchInitialContentDetails() async {
    debugPrint("fetchInitialContentDetails() called for contentId=$contentId");
    state = state.copyWith(isLoading: true, error: null, contentDetails: null);
    try {
      final response = await _contentDetailsService.fetchContentDetails(
        contentType: contentType,
        contentId: contentId,
        page: 1,
      );
      final details = response.data;
      final hasNext = details.pagination.hasNext;
      debugPrint(
          "fetchInitialContentDetails() success: fetched details for contentId=$contentId");
      state = state.copyWith(
        isLoading: false,
        contentDetails: details,
        currentPage: details.pagination.currentPage,
        hasNext: hasNext,
      );
    } catch (e) {
      debugPrint("fetchInitialContentDetails() error: $e");
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Fetch the next page of comments and append them to the current content details
  Future<void> fetchNextComments() async {
    if (state.isLoadingMore) {
      debugPrint("fetchNextComments() aborted: already loading more");
      return;
    }
    if (!state.hasNext) {
      debugPrint("fetchNextComments() aborted: no next page available");
      return;
    }

    final nextPage = state.currentPage + 1;
    debugPrint("fetchNextComments() called, nextPage = $nextPage");
    state = state.copyWith(isLoadingMore: true, error: null);

    try {
      final response = await _contentDetailsService.fetchContentDetails(
        contentType: contentType,
        contentId: contentId,
        page: nextPage,
      );
      final newDetails = response.data;

      // Append new comments.
      final List<Comment> updatedComments = [
        ...state.contentDetails?.comments ?? [],
        ...newDetails.comments.cast<Comment>(),
      ];

      // Use copyWith on ContentDetails to update the comments + pagination
      final updatedContentDetails = state.contentDetails?.copyWith(
        comments: updatedComments,
        pagination: newDetails.pagination,
      );

      debugPrint(
          "fetchNextComments() success: appended ${newDetails.comments.length} comments");
      state = state.copyWith(
        isLoadingMore: false,
        currentPage: nextPage,
        hasNext: newDetails.pagination.hasNext,
        contentDetails: updatedContentDetails,
      );
    } catch (e) {
      debugPrint("fetchNextComments() error: $e");
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }
}

// final List<Comment> updatedComments = [
//   ...state.contentDetails?.comments ?? [],
//   ...newDetails.comments.cast<Comment>(),
// ];
