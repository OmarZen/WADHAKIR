import 'package:wadhakir/data/models/history_event_model.dart';

abstract class IslamicHistoryRepository {
  /// Load a page of history events
  ///
  /// [page] - The page number (0-indexed)
  /// [pageSize] - Number of items per page
  /// Returns a list of HistoryEvent for the requested page
  Future<List<HistoryEvent>> loadPage({
    required int page,
    required int pageSize,
  });

  /// Get the total number of events available
  Future<int> getTotalCount();

  /// Search events by query
  ///
  /// [query] - The search query
  /// [page] - The page number for paginated search results
  /// [pageSize] - Number of items per page
  Future<List<HistoryEvent>> searchEvents({
    required String query,
    required int page,
    required int pageSize,
  });

  /// Get total count of search results
  Future<int> getSearchResultsCount(String query);
}
