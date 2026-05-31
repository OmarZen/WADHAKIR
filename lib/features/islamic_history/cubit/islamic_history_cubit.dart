import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wadhakir/data/models/history_event_model.dart';
import 'package:wadhakir/domain/repositories/islamic_history_repository.dart';
import 'package:wadhakir/features/islamic_history/cubit/islamic_history_state.dart';

class IslamicHistoryCubit extends Cubit<IslamicHistoryState> {
  final IslamicHistoryRepository _repository;
  static const int _pageSize = 20;

  Timer? _searchDebounce;

  IslamicHistoryCubit({required IslamicHistoryRepository repository})
    : _repository = repository,
      super(const IslamicHistoryInitial());

  /// Load initial page of events
  Future<void> loadInitialEvents() async {
    try {
      emit(const IslamicHistoryLoading());

      final events = await _repository.loadPage(page: 0, pageSize: _pageSize);

      final totalCount = await _repository.getTotalCount();
      final hasMorePages = events.length < totalCount;

      emit(
        IslamicHistoryLoaded(
          events: events,
          totalCount: totalCount,
          currentPage: 0,
          hasMorePages: hasMorePages,
        ),
      );
    } catch (e) {
      emit(IslamicHistoryError(e.toString()));
    }
  }

  /// Load next page of events
  Future<void> loadMoreEvents() async {
    if (state is! IslamicHistoryLoaded) return;

    final currentState = state as IslamicHistoryLoaded;

    // Don't load if already loading or no more pages
    if (currentState.isLoadingMore || !currentState.hasMorePages) {
      return;
    }

    try {
      // Show loading indicator for next page
      emit(currentState.copyWith(isLoadingMore: true));

      final nextPage = currentState.currentPage + 1;

      List<HistoryEvent> newEvents;
      if (currentState.searchQuery.isEmpty) {
        newEvents = await _repository.loadPage(
          page: nextPage,
          pageSize: _pageSize,
        );
      } else {
        newEvents = await _repository.searchEvents(
          query: currentState.searchQuery,
          page: nextPage,
          pageSize: _pageSize,
        );
      }

      final allEvents = [...currentState.events, ...newEvents];
      final hasMorePages = allEvents.length < currentState.totalCount;

      emit(
        IslamicHistoryLoaded(
          events: allEvents,
          totalCount: currentState.totalCount,
          currentPage: nextPage,
          hasMorePages: hasMorePages,
          searchQuery: currentState.searchQuery,
        ),
      );
    } catch (e) {
      // Restore previous state on error
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }

  /// Search events with debouncing
  void searchEvents(String query) {
    // Cancel previous debounce timer
    _searchDebounce?.cancel();

    // Create new debounce timer
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  /// Perform the actual search
  Future<void> _performSearch(String query) async {
    try {
      emit(const IslamicHistoryLoading());

      final events = await _repository.searchEvents(
        query: query,
        page: 0,
        pageSize: _pageSize,
      );

      final totalCount = await _repository.getSearchResultsCount(query);
      final hasMorePages = events.length < totalCount;

      emit(
        IslamicHistoryLoaded(
          events: events,
          totalCount: totalCount,
          currentPage: 0,
          hasMorePages: hasMorePages,
          searchQuery: query,
        ),
      );
    } catch (e) {
      emit(IslamicHistoryError(e.toString()));
    }
  }

  /// Clear search and reload initial events
  Future<void> clearSearch() async {
    await loadInitialEvents();
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }
}
