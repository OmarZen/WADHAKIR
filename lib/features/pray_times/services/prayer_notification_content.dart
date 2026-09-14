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
  /// The two **silent** adhan channels, and the whole of the channel set the
  /// prayers use since Stage 3.
  ///
  /// They replace fifteen sounding ones — thirteen `adhan_<key>_v1`, one per
  /// bundled adhan, plus a system-beep channel each for Fajr and the other
  /// four. That fan-out existed because a channel's sound is immutable once
  /// created, so a per-sound channel was the only way to let the user pick an
  /// adhan. Now that `AdhanPlaybackService` owns the audio, the sound is not on
  /// the channel at all and there is nothing left to fan out over.
  ///
  /// Both keys are new for the same immutability reason: the `_v1` channels can
  /// never be made to stop sounding, and leaving them in the path would play
  /// the adhan twice.
  ///
  /// Fajr keeps a channel of its own. Importance, vibration and lock-screen
  /// visibility are the user's to change per channel, and Fajr is the prayer
  /// people most often want treated differently — it is also what a Fajr-only
  /// Do-Not-Disturb bypass would need, without minting keys a third time.
  ///
  /// **Must match `PrayerNotifier.ADHAN_CHANNEL_ID` / `FAJR_ADHAN_CHANNEL_ID`.**
  static const String adhanChannelKey = 'prayer_adhan_v2';
  static const String fajrAdhanChannelKey = 'prayer_adhan_fajr_v2';

  /// The retired sounding channels, kept as constants for two reasons.
  ///
  /// They have to be removed by key — Android never garbage-collects a deleted
  /// channel, so without that they linger in the user's system notification
  /// settings forever on every upgraded install.
  ///
  /// And the plugin fallback path on Android still needs one of them. That path
  /// has no way to reach a native service, so its sound has to come from a
  /// channel; see `_ensureLegacySoundChannel` in the notification repository,
  /// which recreates exactly the one the chosen adhan needs.
  static String legacyAdhanChannelKey(String soundKey) =>
      'adhan_${soundKey}_v1';
  static const String legacyFajrDefaultChannelKey =
      'fajr_channel_default_sound';
  static const String legacyPrayersDefaultChannelKey =
      'prayers_channel_default_sound';

  /// The notification group all five prayers share.
  static const String groupKey = 'prayer_notifications';

  /// The channel for the "your timezone changed" notice.
  ///
  /// **Must match `PrayerNotifier.NOTICE_CHANNEL_ID` in Kotlin.** That notice is
  /// posted from a broadcast receiver with no Flutter engine alive, but the
  /// channel has to be declared on the Dart side too: `initialize()` replaces
  /// the entire channel set at every cold start, so one only Kotlin created
  /// would be deleted and the notice dropped for having no channel.
  static const String locationNoticeChannelKey =
      'prayer_location_notice_channel';

  final int id;

  /// The Android channel this notification is posted to — [adhanChannelKey] or
  /// [fajrAdhanChannelKey]. Silent: the sound belongs to the playback service.
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
  /// beep.
  ///
  /// Consumed by iOS as a `customSound`, and — since Stage 3 — by
  /// `AdhanPlaybackService` on Android, which plays it. It used to matter on
  /// Android only for API 24/25, because from Oreo the channel owned the sound.
  final String? androidRawRes;

  final bool vibrate;

  /// Whether the adhan should sound through a silenced phone.
  ///
  /// On Android the service plays on `USAGE_ALARM`, which ignores the ringer
  /// the way an alarm clock does. True — the default — keeps that; false makes
  /// the fire path post the card without starting playback when the ringer is
  /// off. Inert on iOS, where the notification's sound follows the system's own
  /// rules and the app has no say.
  final bool overrideSilent;

  const PrayerNotificationContent({
    required this.id,
    required this.channelKey,
    required this.title,
    required this.body,
    required this.payload,
    required this.useCustomAdhan,
    required this.androidRawRes,
    required this.vibrate,
    required this.overrideSilent,
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

    // The chosen adhan no longer decides the channel — it decides what the
    // service plays. All that is left for the channel to carry is whether this
    // is Fajr.
    final channelKey = planned.prayer.isFajr
        ? fajrAdhanChannelKey
        : adhanChannelKey;

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
      overrideSilent: planned.settings.overrideSilentMode,
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

  /// `4:38 صباحاً • القاهرة`.
  ///
  /// Shared with the persistent "next prayer" card so the two read the same,
  /// and so the roll-forward — which renders that card from a ledger row's
  /// `body` with no Dart alive — cannot drift from what Dart would have written.
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
