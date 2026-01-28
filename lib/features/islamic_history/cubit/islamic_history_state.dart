import 'package:equatable/equatable.dart';
import 'package:wadhakir/data/models/history_event_model.dart';

abstract class IslamicHistoryState extends Equatable {
  const IslamicHistoryState();

  @override
  List<Object?> get props => [];
}

class IslamicHistoryInitial extends IslamicHistoryState {
  const IslamicHistoryInitial();
}

class IslamicHistoryLoading extends IslamicHistoryState {
  const IslamicHistoryLoading();
}

class IslamicHistoryLoaded extends IslamicHistoryState {
  final List<HistoryEvent> events;
  final int totalCount;
  final int currentPage;
  final bool hasMorePages;
  final bool isLoadingMore;
  final String searchQuery;

  const IslamicHistoryLoaded({
    required this.events,
    required this.totalCount,
    required this.currentPage,
    required this.hasMorePages,
    this.isLoadingMore = false,
    this.searchQuery = '',
  });

  IslamicHistoryLoaded copyWith({
    List<HistoryEvent>? events,
    int? totalCount,
    int? currentPage,
    bool? hasMorePages,
    bool? isLoadingMore,
    String? searchQuery,
  }) {
    return IslamicHistoryLoaded(
      events: events ?? this.events,
      totalCount: totalCount ?? this.totalCount,
      currentPage: currentPage ?? this.currentPage,
      hasMorePages: hasMorePages ?? this.hasMorePages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
        events,
        totalCount,
        currentPage,
        hasMorePages,
        isLoadingMore,
        searchQuery,
      ];
}

class IslamicHistoryError extends IslamicHistoryState {
  final String message;

  const IslamicHistoryError(this.message);

  @override
  List<Object?> get props => [message];
}
