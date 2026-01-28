import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:wadhakir/data/models/history_event_model.dart';
import 'package:wadhakir/domain/repositories/islamic_history_repository.dart';

class IslamicHistoryRepositoryImpl implements IslamicHistoryRepository {
  // Cache for all events (loaded once)
  List<HistoryEvent>? _allEvents;
  bool _isLoading = false;

  /// Load all events from JSON file into memory (called once)
  Future<List<HistoryEvent>> _loadAllEvents() async {
    if (_allEvents != null) {
      return _allEvents!;
    }

    // Prevent multiple simultaneous loads
    if (_isLoading) {
      while (_isLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _allEvents!;
    }

    _isLoading = true;

    try {
      final String response = await rootBundle.loadString(
        'assets/json_data/history.json',
      );
      final List<dynamic> data = json.decode(response);

      _allEvents = data
          .map((json) => HistoryEvent.fromJson(json as Map<String, dynamic>))
          .toList();

      return _allEvents!;
    } finally {
      _isLoading = false;
    }
  }

  @override
  Future<List<HistoryEvent>> loadPage({
    required int page,
    required int pageSize,
  }) async {
    final allEvents = await _loadAllEvents();

    final startIndex = page * pageSize;
    final endIndex = (startIndex + pageSize).clamp(0, allEvents.length);

    if (startIndex >= allEvents.length) {
      return [];
    }

    return allEvents.sublist(startIndex, endIndex);
  }

  @override
  Future<int> getTotalCount() async {
    final allEvents = await _loadAllEvents();
    return allEvents.length;
  }

  @override
  Future<List<HistoryEvent>> searchEvents({
    required String query,
    required int page,
    required int pageSize,
  }) async {
    if (query.isEmpty) {
      return loadPage(page: page, pageSize: pageSize);
    }

    final allEvents = await _loadAllEvents();
    final filteredEvents =
        allEvents.where((event) => event.matchesSearchQuery(query)).toList();

    final startIndex = page * pageSize;
    final endIndex = (startIndex + pageSize).clamp(0, filteredEvents.length);

    if (startIndex >= filteredEvents.length) {
      return [];
    }

    return filteredEvents.sublist(startIndex, endIndex);
  }

  @override
  Future<int> getSearchResultsCount(String query) async {
    if (query.isEmpty) {
      return getTotalCount();
    }

    final allEvents = await _loadAllEvents();
    return allEvents.where((event) => event.matchesSearchQuery(query)).length;
  }

  /// Clear cache (useful for testing or if data needs to be reloaded)
  void clearCache() {
    _allEvents = null;
  }
}
