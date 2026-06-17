import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wadhakir/core/constants/app_constants.dart';
import 'package:wadhakir/data/models/salah/salah_log_model.dart';
import 'package:wadhakir/domain/repositories/salah_tracker_repository.dart';

/// SharedPreferences-backed implementation of [SalahTrackerRepository].
/// Mirrors WirdRepositoryImpl (in-memory cache + broadcast stream + corrupted
/// data fallback). A single JSON blob is stored under one key.
class SalahTrackerRepositoryImpl implements SalahTrackerRepository {
  static const String _logKey = AppConstants.salahTrackerLogKey;

  final SharedPreferences _sharedPreferences;
  final StreamController<SalahLogModel> _logController =
      StreamController<SalahLogModel>.broadcast();

  SalahLogModel? _cachedLog;

  SalahTrackerRepositoryImpl(this._sharedPreferences);

  @override
  Future<SalahLogModel> getLog() async => _cachedLog ?? _readFromPrefs();

  /// Synchronous cache-or-parse read. Lets eager consumers (e.g. day-rollover
  /// handling) read the log without awaiting. Mirrors the azkar repo's
  /// getCachedOrParse(). Does NOT push to the stream.
  SalahLogModel getCachedOrParse() {
    if (_cachedLog != null) return _cachedLog!;
    final raw = _sharedPreferences.getString(_logKey);
    if (raw == null || raw.isEmpty) {
      _cachedLog = SalahLogModel.defaultSettings();
      return _cachedLog!;
    }
    try {
      _cachedLog = SalahLogModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      _cachedLog = SalahLogModel.defaultSettings();
    }
    return _cachedLog!;
  }

  SalahLogModel _readFromPrefs() {
    final raw = _sharedPreferences.getString(_logKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        _cachedLog =
            SalahLogModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        // Corrupted data — drop it and fall back to the empty default.
        _sharedPreferences.remove(_logKey);
        _cachedLog = SalahLogModel.defaultSettings();
      }
    } else {
      _cachedLog = SalahLogModel.defaultSettings();
    }
    _logController.add(_cachedLog!);
    return _cachedLog!;
  }

  @override
  Future<void> setLog(SalahLogModel log) async {
    await _sharedPreferences.setString(_logKey, jsonEncode(log.toJson()));
    _cachedLog = log;
    _logController.add(_cachedLog!);
  }

  @override
  Stream<SalahLogModel> get logStream => _logController.stream;

  @override
  Future<void> clearLog() async {
    await _sharedPreferences.remove(_logKey);
    _cachedLog = SalahLogModel.defaultSettings();
    _logController.add(_cachedLog!);
  }

  /// Dispose the stream controller when no longer needed.
  void dispose() {
    _logController.close();
  }
}
