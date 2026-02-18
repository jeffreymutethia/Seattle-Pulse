import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seattle_pulse_mobile/src/features/feed/data/models/content_model.dart';
import 'package:seattle_pulse_mobile/src/features/feed/data/service/content_service.dart';
import 'package:seattle_pulse_mobile/src/features/feed/providers/content_state.dart';
import 'package:seattle_pulse_mobile/src/features/mypulse/data/service/mypulse_service.dart';
import 'package:seattle_pulse_mobile/src/features/mypulse/providers/mypulse_state.dart';

class MypulseNotifier extends StateNotifier<MyPulseState> {
  final MypulseService _mypulseService;

  MypulseNotifier(this._mypulseService) : super(MyPulseState());

  // Fetch the very first page
  Future<void> fetchFirstPage() async {
    debugPrint("fetchFirstPage() called");
    state = state.copyWith(isLoading: true, error: null, contents: []);
    try {
      final response = await _mypulseService.fetchMypulse(page: 1);

      final newContents = response.data.content;
      final hasNext = response.pagination.hasNext;

      debugPrint("fetchFirstPage() success: fetched ${newContents.length} items, hasNext=$hasNext");

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
    debugPrint("fetchNextPage() called, nextPage = $nextPage");

    state = state.copyWith(isLoadingMore: true, error: null);

    try {
      final response = await _mypulseService.fetchMypulse(page: nextPage);
      final newContents = response.data.content;
      final hasNext = response.pagination.hasNext;

      debugPrint("fetchNextPage() success: fetched ${newContents.length} items, hasNext=$hasNext");

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
