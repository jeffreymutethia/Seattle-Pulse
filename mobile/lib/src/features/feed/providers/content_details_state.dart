import 'package:seattle_pulse_mobile/src/features/feed/data/models/content_detail_model.dart';

class ContentDetailsState {
  final bool isLoading;         // For the initial load
  final bool isLoadingMore;     // For paginating additional comment pages
  final String? error;
  final ContentDetails? contentDetails; // The content details along with comments, etc.
  final int currentPage;
  final bool hasNext;

  ContentDetailsState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.contentDetails,
    this.currentPage = 1,
    this.hasNext = true,
  });

  ContentDetailsState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    ContentDetails? contentDetails,
    int? currentPage,
    bool? hasNext,
  }) {
    return ContentDetailsState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      contentDetails: contentDetails ?? this.contentDetails,
      currentPage: currentPage ?? this.currentPage,
      hasNext: hasNext ?? this.hasNext,
    );
  }
}
