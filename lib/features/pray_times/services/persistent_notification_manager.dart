import 'package:flutter/foundation.dart';
import 'native_persistent_notifier.dart';
import 'prayer_notification_content.dart';
import 'prayer_notification_service.dart';
import '../../../data/models/prayer_times_model.dart';

/// Keeps the ongoing "next prayer" card up to date.
///
/// ## What changed, and why it mattered
///
/// This used to run `Timer.periodic(Duration(seconds: 1))` and post a whole
/// notification across the platform channel on every tick — **86,400 posts and
/// platform round-trips a day**, forever, to animate a countdown. It was the
/// single largest battery cost in the app, and battery drain is the most common
/// reason a prayer app is uninstalled.
///
/// It was also wrong in the way that mattered most. A Dart timer only runs
/// while the app does, so the number froze the moment the user left the app —
/// which is precisely when they would glance at the shade to see how long is
/// left.
///
/// Android has rendered countdowns natively since API 24: `setWhen(instant)`
/// plus `setUsesChronometer` and `setChronometerCountDown`. The system counts,
/// with no process alive and **no updates at all**. The plugin does not expose
/// those flags, which is why this was blocked until R2 built a native
/// notification path — so the card is now posted from Kotlin.
///
/// ## What now updates it
///
/// Two things, both of them events rather than ticks:
///
///  * this class, when prayer times change or the feature is switched on;
///  * `PrayerAlarmReceiver`, as each alarm fires — the only moment the *next*
///    prayer becomes a different prayer. That one runs with no Flutter engine,
///    which is what keeps the card honest while the app is closed.
///
/// Five or six posts a day, down from 86,400.
class PersistentNotificationManager {
  static final PersistentNotificationManager _instance =
      PersistentNotificationManager._internal();
  factory PersistentNotificationManager() => _instance;

  PersistentNotificationManager._internal()
    : _notificationService = PrayerNotificationService(),
      _nativeNotifier = const MethodChannelPersistentNotifier();

  /// Test seam. The production path is the singleton above.
  @visibleForTesting
  PersistentNotificationManager.forTesting({
    required NativePersistentNotifier notifier,
    PrayerNotificationService? fallbackService,
  }) : _nativeNotifier = notifier,
       _notificationService = fallbackService ?? PrayerNotificationService();

  /// The title, with a `{prayer}` token Kotlin substitutes.
  ///
  /// Kept here because the native side has to re-render this card on its own
  /// when an alarm fires, and a second author of Arabic copy on the native side
  /// is the drift the whole wire format exists to prevent.
  @visibleForTesting
  static const String titleFormat = '🕌 الصلاة القادمة: {prayer}';

  final PrayerNotificationService _notificationService;
  final NativePersistentNotifier _nativeNotifier;

  bool _isActive = false;
  PrayerTimesModel? _currentPrayerTimes;
  String? _locationName;

  /// Shows the card and leaves Android to count.
  ///
  /// No timer is started. If one is ever added back here, read the class doc
  /// first — the countdown does not need it, and the cost is 86,400 platform
  /// round-trips a day.
  Future<void> start({
    required PrayerTimesModel prayerTimes,
    String? locationName,
  }) async {
    _currentPrayerTimes = prayerTimes;
    _locationName = locationName;

    if (_isActive) {
      // Already showing. Still re-post: the caller reaches here on every
      // reschedule, and the times it just handed over may be newer than the
      // ones the card was built from.
      await _post();
      return;
    }

    _isActive = true;
    await _post();
  }

  /// Takes the card down.
  ///
  /// Deliberately NOT guarded on [_isActive]. The card is now owned natively
  /// and rolled forward by a broadcast receiver, so it outlives this process —
  /// while `_isActive` is a Dart field that starts false in every new one. The
  /// guard meant that a user who turned the card off in a session where it had
  /// not yet been started (the setting toggled before prayer times finished
  /// loading, or a reschedule that found no times) never reached `hide`, the
  /// native flag stayed set, and the receiver re-posted the card after every
  /// prayer forever. There was no way back from it short of clearing app data.
  ///
  /// Hiding something that is already hidden costs one no-op cancel.
  Future<void> stop() async {
    _isActive = false;
    _currentPrayerTimes = null;
    _locationName = null;

    if (_useNativeRenderer) {
      await _nativeNotifier.hide();
    } else {
      await _notificationService.hidePersistentNotification();
    }
  }

  /// Called when prayer times are recomputed.
  Future<void> updatePrayerTimes({
    required PrayerTimesModel prayerTimes,
    String? locationName,
  }) async {
    _currentPrayerTimes = prayerTimes;
    _locationName = locationName;
    if (_isActive) await _post();
  }

  /// Whether the countdown is rendered by Android rather than re-posted.
  ///
  /// Android only. Windows keeps the plugin path — `notification_repository_
  /// impl_windows.dart` has its own implementation — and iOS never gets here at
  /// all: an ongoing notification is not a thing iOS has, so the caller in
  /// `PrayerTimesCubit` is already guarded on platform.
  bool get _useNativeRenderer =>
      defaultTargetPlatform == TargetPlatform.android;

  Future<void> _post() async {
    final times = _currentPrayerTimes;
    if (times == null) return;

    final next = _getNextPrayer(DateTime.now(), times);
    if (next == null) return;

    final prayerAt = next['time'] as DateTime;
    final body = PrayerNotificationContent.bodyText(prayerAt, _locationName);

    try {
      if (_useNativeRenderer) {
        await _nativeNotifier.show(
          titleFormat: titleFormat,
          prayerName: next['nameAr'] as String,
          body: body,
          prayerAt: prayerAt,
        );
      } else {
        await _notificationService.showPersistentNotification(
          nextPrayerName: next['nameEn'] as String,
          nextPrayerNameArabic: next['nameAr'] as String,
          nextPrayerTime: prayerAt,
          locationName: _locationName,
        );
      }
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
