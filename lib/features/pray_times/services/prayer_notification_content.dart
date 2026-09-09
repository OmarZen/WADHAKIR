import 'package:flutter/foundation.dart';
import 'package:wadhakir/core/constants/adhan_sounds.dart';
import 'package:wadhakir/features/pray_times/services/prayer_schedule_planner.dart';

/// Everything that is *rendered* about one prayer notification, decided without
/// touching a plugin or a platform channel.
///
/// ## Why this exists
///
/// [PrayerSchedulePlanner] decides *which* notifications should exist and
/// *when* they fire. This decides what each one says, which channel carries its
/// sound, and what the tap payload is. Those were previously computed inside
/// `_MobileNotificationRepositoryImpl._render`, welded to
/// `awesome_notifications`' `NotificationContent`.
///
/// R2 gives the same plan a second consumer — a native `AlarmManager` bridge
/// that renders the notification in Kotlin. Kotlin must not re-derive Arabic
/// copy or channel keys: two renderers drifting apart is how the wrong adhan
/// ends up on the wrong channel. So the rendering happens once, here, in Dart,
/// and both consumers are handed the finished result.
@immutable
class PrayerNotificationContent {
  /// System-beep channels for the "Default" sound option. Fajr has its own so
  /// its importance and vibration can diverge later without touching the other
  /// four.
  static const String fajrDefaultChannelKey = 'fajr_channel_default_sound';
  static const String prayersDefaultChannelKey =
      'prayers_channel_default_sound';

  /// The notification group all five prayers share.
  static const String groupKey = 'prayer_notifications';

  final int id;

  /// The Android channel that owns this notification's sound. For a chosen
  /// adhan this is `adhan_<key>_v1`, whose mp3 is baked in at channel creation
  /// so the OS plays it with no app process alive.
  final String channelKey;

  final String title;
  final String body;

  /// Read back by the deep-link router on tap. Values are all strings because
  /// that is what both the plugin payload and an Android `Intent` extra carry.
  final Map<String, String> payload;

  /// Whether a real adhan mp3 backs this notification, as opposed to the
  /// system beep. iOS needs it to decide whether to attach a `customSound`.
  final bool useCustomAdhan;

  /// The `res/raw` resource name of the chosen adhan, or null for the default
  /// beep. Only iOS consumes it; on Android the channel already owns the sound.
  final String? androidRawRes;

  final bool vibrate;

  const PrayerNotificationContent({
    required this.id,
    required this.channelKey,
    required this.title,
    required this.body,
    required this.payload,
    required this.useCustomAdhan,
    required this.androidRawRes,
    required this.vibrate,
  });

  /// Renders one planned notification.
  ///
  /// [locationName] is appended to the body when present; it is part of the
  /// reschedule signature upstream precisely because it lands here.
  factory PrayerNotificationContent.of(
    PlannedPrayerNotification planned, {
    String? locationName,
  }) {
    final adhan = AdhanSounds.byAssetPath(planned.settings.customSoundPath);
    final useCustomAdhan = adhan?.androidRawRes != null;

    final channelKey = useCustomAdhan
        ? 'adhan_${adhan!.key}_v1'
        : (planned.prayer.isFajr
              ? fajrDefaultChannelKey
              : prayersDefaultChannelKey);

    return PrayerNotificationContent(
      id: planned.id,
      channelKey: channelKey,
      title:
          '🕌 حان وقت صلاة ${planned.prayer.arabicName}'
          '${leadTimeText(planned.leadTime)}',
      body: bodyText(planned.prayerTime, locationName),
      payload: {
        'type': 'prayer',
        'prayer': planned.prayer.key,
        'time': planned.prayerTime.toIso8601String(),
        // The moment the notification actually fires (= prayerTime minus any
        // "before X min" offset). The app-open replay guard compares against
        // THIS, not 'time', so a valid on-fire adhan isn't wrongly suppressed
        // when the user picked a before-prayer timing.
        'fireTime': planned.fireTime.toIso8601String(),
        'soundPath': planned.settings.customSoundPath ?? '',
        'useCustomAdhan': useCustomAdhan.toString(),
      },
      useCustomAdhan: useCustomAdhan,
      androidRawRes: adhan?.androidRawRes,
      vibrate: planned.settings.vibration,
    );
  }

  /// The parenthetical that tells the reader this fired early.
  ///
  /// Derived from the planned duration rather than re-switching on the timing
  /// enum, so a new lead-time option cannot silently render as "on time".
  @visibleForTesting
  static String leadTimeText(Duration leadTime) {
    final minutes = leadTime.inMinutes;
    if (minutes == 0) return '';
    // Arabic counts 3-10 with the plural and 11+ with the singular. Only 5, 10
    // and 15 are reachable today; the rule is written out so a future option
    // does not read as broken Arabic.
    final noun = minutes >= 3 && minutes <= 10 ? 'دقائق' : 'دقيقة';
    return ' (بعد $minutes $noun)';
  }

  @visibleForTesting
  static String bodyText(DateTime prayerTime, String? locationName) {
    final time = formatTime(prayerTime);
    final location = locationName ?? '';
    return location.isEmpty ? time : '$time • $location';
  }

  /// 12-hour Arabic clock, e.g. `4:38 صباحاً`.
  @visibleForTesting
  static String formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'مساءً' : 'صباحاً';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}
