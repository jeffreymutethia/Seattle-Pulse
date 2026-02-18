import 'package:seattle_pulse_mobile/src/features/feed/data/models/content_model.dart';

class ContentState {
  final bool isLoading;       // For the initial load
  final bool isLoadingMore;   // For loading more pages (spinner at the bottom)
  final String? error;
  final List<Content> contents;
  final int currentPage;
  final bool hasNext;

  ContentState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.contents = const [],
    this.currentPage = 1,
    this.hasNext = true,
  });

  ContentState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    List<Content>? contents,
    int? currentPage,
    bool? hasNext,
  }) {
    return ContentState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      contents: contents ?? this.contents,
      currentPage: currentPage ?? this.currentPage,
      hasNext: hasNext ?? this.hasNext,
    );
  }
}
