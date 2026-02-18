
import 'package:seattle_pulse_mobile/src/features/mypulse/data/models/mypulse_model.dart';

class MyPulseState {
  final bool isLoading;      
  final bool isLoadingMore;   
  final String? error;
  final List<Content> contents;
  final int currentPage;
  final bool hasNext;

  MyPulseState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.contents = const [],
    this.currentPage = 1,
    this.hasNext = true,
  });

  MyPulseState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    List<Content>? contents,
    int? currentPage,
    bool? hasNext,
  }) {
    return MyPulseState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      contents: contents ?? this.contents,
      currentPage: currentPage ?? this.currentPage,
      hasNext: hasNext ?? this.hasNext,
    );
  }
}
