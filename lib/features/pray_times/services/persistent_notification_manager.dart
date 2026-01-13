import 'dart:async';
import 'package:flutter/foundation.dart';
import 'prayer_notification_service.dart';
import '../../../data/models/prayer_times_model.dart';

/// Manager for persistent notification that updates every minute
class PersistentNotificationManager {
  static final PersistentNotificationManager _instance =
      PersistentNotificationManager._internal();
  factory PersistentNotificationManager() => _instance;
  PersistentNotificationManager._internal();

  final PrayerNotificationService _notificationService =
      PrayerNotificationService();

  Timer? _updateTimer;
  bool _isActive = false;
  PrayerTimesModel? _currentPrayerTimes;
  String? _locationName;

  /// Start the persistent notification with auto-update
  Future<void> start({
    required PrayerTimesModel prayerTimes,
    String? locationName,
  }) async {
    if (_isActive) {
      debugPrint('⏰ Persistent notification already running');
      return;
    }

    _currentPrayerTimes = prayerTimes;
    _locationName = locationName;
    _isActive = true;

    // Show initial notification
    await _updateNotification();

    // Update every minute
    _updateTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      await _updateNotification();
    });

    debugPrint('✅ Persistent notification started');
  }

  /// Stop the persistent notification
  Future<void> stop() async {
    if (!_isActive) return;

    _updateTimer?.cancel();
    _updateTimer = null;
    _isActive = false;
    _currentPrayerTimes = null;
    _locationName = null;

    await _notificationService.hidePersistentNotification();
    debugPrint('🛑 Persistent notification stopped');
  }

  /// Update prayer times (called when prayer times are refreshed)
  Future<void> updatePrayerTimes({
    required PrayerTimesModel prayerTimes,
    String? locationName,
  }) async {
    _currentPrayerTimes = prayerTimes;
    _locationName = locationName;

    if (_isActive) {
      await _updateNotification();
      debugPrint('🔄 Persistent notification updated with new prayer times');
    }
  }

  /// Update the notification with current prayer info
  Future<void> _updateNotification() async {
    if (_currentPrayerTimes == null) {
      debugPrint('⚠️ No prayer times available for notification');
      return;
    }

    try {
      final now = DateTime.now();
      final nextPrayerInfo = _getNextPrayer(now, _currentPrayerTimes!);

      if (nextPrayerInfo == null) {
        debugPrint('⚠️ Could not determine next prayer');
        return;
      }

      await _notificationService.showPersistentNotification(
        nextPrayerName: nextPrayerInfo['nameEn']!,
        nextPrayerNameArabic: nextPrayerInfo['nameAr']!,
        nextPrayerTime: nextPrayerInfo['time'] as DateTime,
        locationName: _locationName,
      );

      debugPrint(
        '📱 Updated notification: ${nextPrayerInfo['nameAr']} at ${nextPrayerInfo['time']}',
      );
    } catch (e) {
      debugPrint('❌ Error updating persistent notification: $e');
    }
  }

  /// Get the next prayer information
  Map<String, dynamic>? _getNextPrayer(
    DateTime now,
    PrayerTimesModel prayerTimes,
  ) {
    final prayers = [
      {'nameEn': 'Fajr', 'nameAr': 'الفجر', 'time': prayerTimes.fajr},
      {'nameEn': 'Dhuhr', 'nameAr': 'الظهر', 'time': prayerTimes.dhuhr},
      {'nameEn': 'Asr', 'nameAr': 'العصر', 'time': prayerTimes.asr},
      {'nameEn': 'Maghrib', 'nameAr': 'المغرب', 'time': prayerTimes.maghrib},
      {'nameEn': 'Isha', 'nameAr': 'العشاء', 'time': prayerTimes.isha},
    ];

    // Find the next prayer
    for (final prayer in prayers) {
      final prayerTime = prayer['time'] as DateTime;
      if (prayerTime.isAfter(now)) {
        return prayer;
      }
    }

    // If no prayer found today, return Fajr tomorrow
    return {
      'nameEn': 'Fajr',
      'nameAr': 'الفجر',
      'time': prayerTimes.fajr.add(const Duration(days: 1)),
    };
  }

  /// Check if the manager is currently active
  bool get isActive => _isActive;
}
