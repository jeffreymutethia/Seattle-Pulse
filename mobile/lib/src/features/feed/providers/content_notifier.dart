import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seattle_pulse_mobile/src/features/feed/data/service/content_service.dart';
import 'package:seattle_pulse_mobile/src/features/feed/providers/content_state.dart';

class ContentNotifier extends StateNotifier<ContentState> {
  final ContentService _contentService;
  int? _currentLocationId; // Track the current location filter

  ContentNotifier(this._contentService) : super(ContentState());

  // Fetch the very first page
  Future<void> fetchFirstPage({int? locationId}) async {
    debugPrint("fetchFirstPage() called with locationId: $locationId");

    // Store the locationId for pagination
    _currentLocationId = locationId;

    state = state.copyWith(isLoading: true, error: null, contents: []);
    try {
      final response = await _contentService.fetchContent(
        page: 1,
        locationId: locationId,
      );

      final newContents = response.data.content;
      final hasNext = response.pagination.hasNext;

      debugPrint(
          "fetchFirstPage() success: fetched ${newContents.length} items, hasNext=$hasNext");

      state = state.copyWith(
        isLoading: false,
        contents: newContents,
        currentPage: 1,
        hasNext: hasNext,
      );
    } catch (e) {
      debugPrint("fetchFirstPage() error: $e");
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Fetch the next page
  Future<void> fetchNextPage() async {
    // Don't load if we're already fetching more or there's no next page
    if (state.isLoadingMore) {
      debugPrint("fetchNextPage() aborted: already loading more");
      return;
    }
    if (!state.hasNext) {
      debugPrint("fetchNextPage() aborted: no next page (hasNext=false)");
      return;
    }

    final nextPage = state.currentPage + 1;
    debugPrint(
        "fetchNextPage() called, nextPage = $nextPage, locationId = $_currentLocationId");

    state = state.copyWith(isLoadingMore: true, error: null);

    try {
      final response = await _contentService.fetchContent(
        page: nextPage,
        locationId: _currentLocationId,
      );
      final newContents = response.data.content;
      final hasNext = response.pagination.hasNext;

      debugPrint(
          "fetchNextPage() success: fetched ${newContents.length} items, hasNext=$hasNext");

      final updatedList = [...state.contents, ...newContents];

      state = state.copyWith(
        isLoadingMore: false,
        contents: updatedList,
        currentPage: nextPage,
        hasNext: hasNext,
      );
    } catch (e) {
      debugPrint("fetchNextPage() error: $e");
      state = state.copyWith(
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }
}
