import 'dart:io';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'notification_repository_impl_windows.dart';
import '../models/notification_settings_model.dart';
import '../../core/constants/adhan_sounds.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../core/time/clock.dart';
import '../../core/constants/app_constants.dart';
import '../../features/pray_times/services/prayer_schedule_planner.dart';
import '../../features/pray_times/services/prayer_notification_content.dart';
import '../../features/pray_times/services/prayer_scheduler.dart';
import '../../features/pray_times/services/native_prayer_alarm_gateway.dart';
import '../../features/pray_times/services/fallback_prayer_alarm_gateway.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Factory class to return the appropriate notification repository implementation
/// based on the current platform
class NotificationRepositoryImpl implements NotificationRepository {
  // Singleton pattern
  static NotificationRepositoryImpl? _instance;

  // Delegate to platform-specific implementation
  late final NotificationRepository _platformRepository;

  factory NotificationRepositoryImpl() {
    _instance ??= NotificationRepositoryImpl._internal();
    return _instance!;
  }

  NotificationRepositoryImpl._internal() {
    // Platform detection: Use Windows implementation on Windows, mobile implementation otherwise
    if (Platform.isWindows) {
      debugPrint('🪟 Using Windows Notification Repository');
      _platformRepository = NotificationRepositoryImplWindows();
    } else {
      debugPrint(
        '📱 Using Mobile Notification Repository (awesome_notifications)',
      );
      _platformRepository = _MobileNotificationRepositoryImpl();
    }
  }

  @override
  Future<void> initialize() => _platformRepository.initialize();

  @override
  bool get usesNativeAlarms => _platformRepository.usesNativeAlarms;

  @override
  Future<bool> requestPermissions() => _platformRepository.requestPermissions();

  @override
  Future<bool> hasPermissions() => _platformRepository.hasPermissions();

  @override
  Future<void> schedulePrayerNotification({
    required String prayerName,
    required String prayerNameArabic,
    required DateTime prayerTime,
    required PrayerNotificationSettings settings,
    String? locationName,
  }) => _platformRepository.schedulePrayerNotification(
    prayerName: prayerName,
    prayerNameArabic: prayerNameArabic,
    prayerTime: prayerTime,
    settings: settings,
    locationName: locationName,
  );

  @override
  Future<void> scheduleAllPrayerNotifications({
    required Map<String, DateTime> prayerTimes,
    required NotificationSettingsModel settings,
    String? locationName,
  }) => _platformRepository.scheduleAllPrayerNotifications(
    prayerTimes: prayerTimes,
    settings: settings,
    locationName: locationName,
  );

  @override
  Future<void> scheduleMultiDayPrayerNotifications({
    required Map<DateTime, Map<String, DateTime>> prayerTimesByDay,
    required NotificationSettingsModel settings,
    String? locationName,
  }) => _platformRepository.scheduleMultiDayPrayerNotifications(
    prayerTimesByDay: prayerTimesByDay,
    settings: settings,
    locationName: locationName,
  );

  @override
  Future<void> cancelPrayerNotification(String prayerName) =>
      _platformRepository.cancelPrayerNotification(prayerName);

  @override
  Future<void> cancelPrayerSchedules() =>
      _platformRepository.cancelPrayerSchedules();

  @override
  Future<void> cancelAllNotifications() =>
      _platformRepository.cancelAllNotifications();

  @override
  Future<bool> hasActiveNotifications() =>
      _platformRepository.hasActiveNotifications();

  @override
  Future<List<int>> getScheduledNotificationIds() =>
      _platformRepository.getScheduledNotificationIds();

  @override
  Future<void> showPersistentNotification({
    required String nextPrayerName,
    required String nextPrayerNameArabic,
    required DateTime nextPrayerTime,
    String? locationName,
  }) => _platformRepository.showPersistentNotification(
    nextPrayerName: nextPrayerName,
    nextPrayerNameArabic: nextPrayerNameArabic,
    nextPrayerTime: nextPrayerTime,
    locationName: locationName,
  );

  @override
  Future<void> hidePersistentNotification() =>
      _platformRepository.hidePersistentNotification();
}

/// Mobile implementation using awesome_notifications
/// This is the original implementation moved into a private class
class _MobileNotificationRepositoryImpl
    implements NotificationRepository, PrayerAlarmGateway {
  static const String _channelKeyFajr = 'fajr_channel';
  static const String _channelKeyPrayers = 'prayers_channel';
  static const String _channelKeyFajrDefault = 'fajr_channel_default_sound';
  static const String _channelKeyPrayersDefault =
      'prayers_channel_default_sound';
  static const String _channelKeyPersistent = 'persistent_prayer_channel';
  // Must match `FastingNotificationService._channelKey`. Both services
  // initialize awesome_notifications independently — calling `initialize()`
  // REPLACES all channels — so each one must register the FULL set the
  // app uses or the other service's channels disappear. Keeping the key in
  // sync makes that safe.
  static const String _channelKeyFasting = 'fasting_reminders_channel';
  // Must match `WirdNotificationService._channelKey`. Registered here too
  // because `initialize()` REPLACES all channels — otherwise the wird
  // channel (added via setChannel) would be wiped whenever this runs.
  static const String _channelKeyWird = 'wird_reminders_channel';
  // Must match `DailyInspirationNotificationService.channelKey`. Same reason as
  // wird — registered here so the eager cold-start initialize() doesn't wipe it.
  static const String _channelKeyDailyInspiration = 'daily_inspiration_channel';
  // Must match `AzkarNotificationService.channelKey`. Registered here so the
  // eager cold-start initialize() doesn't wipe the azkar reminders channel.
  static const String _channelKeyAzkar = 'azkar_reminders_channel';
  // Must match `FeatureDiscoveryService.channelKey`. Low-key re-engagement
  // nudges — registered here for the same channel-replace reason.
  static const String _channelKeyFeatureNudge = 'feature_nudge_channel';
  static const String _channelGroupKey = 'prayer_notifications';

  // The prayer id space (100..214) lives in [PrayerSchedulePlanner], which is
  // now the only place that allocates it.
  static const int _persistentId = 999; // ID for persistent notification

  /// The immediate "does this work?" notification from Settings.
  ///
  /// It used to resolve through the prayer-name id map, whose `default:` arm
  /// returned **0** — an id outside the documented 100..214 window, owned by
  /// nothing, and therefore never cleared by [cancelPrayerSchedules]. Giving
  /// it a real id of its own puts it back inside a range somebody owns.
  static const int _testNotificationId = 998;

  /// The single place `now` comes from on this class's own scheduling path.
  ///
  /// Not a constructor seam: this class is private, constructed in exactly one
  /// place, and welded to the awesome_notifications singleton — a test could
  /// not reach it anyway. The seam that matters is [PrayerScheduler], which
  /// takes a [Clock] and a [PrayerAlarmGateway] and is where the sequencing
  /// actually lives.
  final Clock _clock = systemClock;

  /// Cancels and re-arms the prayer id window from a freshly planned schedule.
  /// This class is its own [PrayerAlarmGateway] — the scheduler decides, the
  /// methods below render.
  ///
  /// Starts on the plugin gateway (`this`) and is replaced during [initialize]
  /// if the native `AlarmManager` bridge answers. Not `final`, because which
  /// gateway owns the alarm table is only knowable after an async probe, and a
  /// reschedule that arrived before that probe finished must still work.
  late PrayerScheduler _scheduler = PrayerScheduler(
    this,
    const PrayerSchedulePlanner(),
    _clock,
  );

  bool _usesNativeAlarms = false;

  @override
  bool get usesNativeAlarms => _usesNativeAlarms;

  // --- PrayerAlarmGateway ---------------------------------------------------

  @override
  Future<void> cancelIds(Iterable<int> ids) async {
    for (final id in ids) {
      // cancelSchedule, NOT cancel. The plugin's own contract: cancelSchedule
      // "has no effect on the currently active notification", while cancel()
      // dismisses it — and dismissing the notification that owns the in-flight
      // channel sound is what stops that sound.
      //
      // This sweep runs on every reschedule, and one of the most common
      // moments to reschedule is the user opening the app because they just
      // heard the adhan. With cancel() that tap silenced it. Removing only the
      // pending schedules leaves a sounding adhan alone, which is the whole
      // point of the app.
      await AwesomeNotifications().cancelSchedule(id);
    }
  }

  @override
  Future<void> arm(PlannedPrayerNotification planned, {String? locationName}) =>
      _scheduleOne(planned, locationName: locationName);

  // Cached local timezone identifier. awesome_notifications reads
  // `TimeZone.getDefault().getID()` on Android, which on some OEM builds
  // returns null and crashes with
  //   "Attempt to invoke virtual method 'int java.util.TimeZone.getOffset(long)' on a null object reference"
  // We resolve and cache it once at init, with a sensible fallback.
  String _localTimeZone = 'UTC';

  Future<String> _resolveTimeZone() async {
    try {
      final tz = await AwesomeNotifications().getLocalTimeZoneIdentifier();
      if (tz.isNotEmpty) return tz;
    } catch (_) {}
    // Fallback: derive an IANA-ish zone label from DateTime.now() offset.
    // The plugin accepts "Etc/GMT+X" style identifiers as a last resort.
    final offset = DateTime.now().timeZoneOffset;
    final hours = offset.inHours;
    // POSIX-style "Etc/GMT" inverts the sign: UTC+3 -> Etc/GMT-3.
    final etc = hours == 0
        ? 'UTC'
        : 'Etc/GMT${hours > 0 ? '-' : '+'}${hours.abs()}';
    debugPrint('NotificationRepository: timezone fallback to $etc');
    return etc;
  }

  /// Build one notification channel per adhan sound, with the mp3 baked in as
  /// `soundSource`. Channel keys are versioned (`_v1`) because Android channel
  /// settings are immutable once created — to change a baked sound later, bump
  /// the version and delete the old key.
  List<NotificationChannel> _adhanSoundChannels() {
    return AdhanSounds.all
        .map(
          (o) => NotificationChannel(
            channelKey: 'adhan_${o.key}_v1',
            channelName: 'أذان: ${o.name}',
            channelDescription: 'تنبيه الصلاة بصوت "${o.name}"',
            importance: NotificationImportance.Max,
            defaultColor: const Color(0xFF20497D),
            ledColor: const Color(0xFF20497D),
            playSound: true,
            soundSource: 'resource://raw/${o.androidRawRes}',
            enableVibration: true,
            vibrationPattern: highVibrationPattern,
            channelShowBadge: true,
            locked: false,
            onlyAlertOnce: true,
            icon: 'resource://drawable/ic_notification',
          ),
        )
        .toList();
  }

  @override
  Future<void> initialize() async {
    // Resolve and cache the local timezone before doing anything else with
    // the plugin so subsequent schedule calls have a valid value to pass.
    _localTimeZone = await _resolveTimeZone();
    debugPrint('NotificationRepository: timezone resolved to $_localTimeZone');

    // Purge the two channels retired when adhan playback moved from the Dart
    // player to per-sound channels. Android never garbage-collects a deleted
    // channel, so without this they linger in the user's system notification
    // settings forever on upgraded installs. Safe to run every launch: nothing
    // schedules to these keys any more, so there are no live notifications for
    // removeChannel to close.
    //
    // Deliberately NOT removing the in-use channels here. removeChannel "closes
    // all current notifications on that channel" (plugin README), and
    // delete-then-recreate cannot "force recreation" anyway: Android un-deletes
    // a channel with all its previous settings when you recreate it with the
    // same id (see NotificationManager.deleteNotificationChannel). The versioned
    // key on the adhan channels below is the mechanism that actually works.
    try {
      await AwesomeNotifications().removeChannel(_channelKeyFajr);
      await AwesomeNotifications().removeChannel(_channelKeyPrayers);
    } catch (e) {
      // Channels might not exist yet, ignore error
    }

    await AwesomeNotifications().initialize(
      'resource://drawable/ic_notification', // Use custom notification icon
      [
        // One channel per adhan sound, each with the mp3 BAKED IN as the
        // channel sound (resource://raw/...). Android bakes the sound into the
        // channel at creation, so the correct adhan plays reliably even when the
        // app is killed — this is the core reliability fix. When the phone is on
        // silent/vibrate, Android suppresses the sound and only the (strong)
        // vibration fires. See AdhanSounds catalog for the key→raw mapping.
        ..._adhanSoundChannels(),
        // Fajr channel - Default notification sound (short beep)
        NotificationChannel(
          channelKey: _channelKeyFajrDefault,
          channelName: 'صلاة الفجر (صوت النظام)',
          channelDescription: 'تنبيهات صلاة الفجر بصوت النظام',
          importance: NotificationImportance.Max,
          defaultColor: const Color(0xFF20497D),
          ledColor: const Color(0xFF20497D),
          playSound: true,
          enableVibration: true,
          channelShowBadge: true,
          locked: false,
          onlyAlertOnce: true,
          icon: 'resource://drawable/ic_notification',
        ),
        // Other prayers channel - Default notification sound (short beep)
        NotificationChannel(
          channelKey: _channelKeyPrayersDefault,
          channelName: 'أوقات الصلاة (صوت النظام)',
          channelDescription: 'تنبيهات الصلوات بصوت النظام',
          importance: NotificationImportance.High,
          defaultColor: const Color(0xFF20497D),
          ledColor: const Color(0xFF20497D),
          playSound: true,
          enableVibration: true,
          channelShowBadge: true,
          locked: false,
          onlyAlertOnce: true,
          icon: 'resource://drawable/ic_notification',
        ),
        // Persistent notification channel - Default importance (no sound)
        NotificationChannel(
          channelKey: _channelKeyPersistent,
          channelName: 'تنبيه دائم لأوقات الصلاة',
          channelDescription:
              'إشعار دائم يعرض موعد الصلاة القادمة مع عداد تنازلي مباشر',
          importance: NotificationImportance.Default,
          defaultColor: const Color(0xFF20497D),
          playSound: false,
          enableVibration: false,
          channelShowBadge: false,
          locked: true, // Prevent user from dismissing
          onlyAlertOnce: true,
          icon: 'resource://drawable/ic_notification',
          enableLights: true,
          ledColor: const Color(0xFF20497D),
        ),
        // Fasting reminders channel - High importance with default sound
        NotificationChannel(
          channelKey: _channelKeyFasting,
          channelName: 'تذكير بالصيام',
          channelDescription: 'تنبيهات صيام الإثنين والخميس',
          importance: NotificationImportance.High,
          defaultColor: const Color(0xFF20497D),
          ledColor: const Color(0xFF20497D),
          playSound: true,
          enableVibration: true,
          channelShowBadge: true,
          locked: false,
          onlyAlertOnce: true,
          icon: 'resource://drawable/ic_notification',
        ),
        // Wird (daily Quran reading) reminder channel.
        NotificationChannel(
          channelKey: _channelKeyWird,
          channelName: 'تذكير الورد',
          channelDescription: 'تذكير الورد اليومي من القرآن الكريم',
          importance: NotificationImportance.High,
          defaultColor: const Color(0xFF20497D),
          ledColor: const Color(0xFF20497D),
          playSound: true,
          enableVibration: true,
          channelShowBadge: true,
          locked: false,
          onlyAlertOnce: true,
          icon: 'resource://drawable/ic_notification',
        ),
        // Daily inspiration (Verse/Dua of the Day) reminder channel.
        NotificationChannel(
          channelKey: _channelKeyDailyInspiration,
          channelName: 'آية وذِكر اليوم',
          channelDescription: 'تذكير يومي بآية أو دعاء أو حديث',
          importance: NotificationImportance.High,
          defaultColor: const Color(0xFF20497D),
          ledColor: const Color(0xFF20497D),
          playSound: true,
          enableVibration: true,
          channelShowBadge: true,
          locked: false,
          onlyAlertOnce: true,
          icon: 'resource://drawable/ic_notification',
        ),
        // Daily azkar reminders (morning/evening, after-prayer, qiyam, etc.).
        NotificationChannel(
          channelKey: _channelKeyAzkar,
          channelName: 'تذكير الأذكار',
          channelDescription:
              'تذكيرات الأذكار اليومية (الصباح، المساء، بعد الصلاة، قيام الليل)',
          importance: NotificationImportance.High,
          defaultColor: const Color(0xFF20497D),
          ledColor: const Color(0xFF20497D),
          playSound: true,
          enableVibration: true,
          channelShowBadge: true,
          locked: false,
          onlyAlertOnce: true,
          icon: 'resource://drawable/ic_notification',
        ),
        // Feature-discovery / re-engagement nudges (low-key, spaced out).
        NotificationChannel(
          channelKey: _channelKeyFeatureNudge,
          channelName: 'اكتشف ميزات التطبيق',
          channelDescription: 'تذكير لطيف بميزات التطبيق التي لم تجرّبها بعد',
          importance: NotificationImportance.Default,
          defaultColor: const Color(0xFF20497D),
          ledColor: const Color(0xFF20497D),
          playSound: true,
          enableVibration: true,
          channelShowBadge: true,
          locked: false,
          onlyAlertOnce: true,
          icon: 'resource://drawable/ic_notification',
        ),
        // Declared here but POSTED FROM KOTLIN — the "your timezone changed,
        // open the app to update prayer times" notice, which is raised from a
        // broadcast receiver with no Flutter engine alive. It has to be in this
        // list anyway: `initialize()` REPLACES the whole channel set, so a
        // channel only Kotlin creates would be deleted at the next cold start
        // and the notice silently dropped for having no channel.
        NotificationChannel(
          channelKey: PrayerNotificationContent.locationNoticeChannelKey,
          channelName: 'تنبيهات مواقيت الصلاة',
          channelDescription: 'تنبيه عند تغيّر المنطقة الزمنية أو الموقع',
          importance: NotificationImportance.Default,
          defaultColor: const Color(0xFF20497D),
          ledColor: const Color(0xFF20497D),
          playSound: true,
          enableVibration: true,
          channelShowBadge: true,
          locked: false,
          onlyAlertOnce: true,
          icon: 'resource://drawable/ic_notification',
        ),
      ],
      channelGroups: [
        NotificationChannelGroup(
          channelGroupKey: _channelGroupKey,
          channelGroupName: 'تنبيهات الصلاة',
        ),
      ],
    );

    // Channels exist now, which matters: the native path posts INTO the channels
    // created above, and a notification sent to a channel key that does not
    // exist is dropped by Android without an error anywhere.
    await _resolveAlarmOwner();
  }

  /// Decides, once per launch, whether the native `AlarmManager` bridge or
  /// `awesome_notifications` owns the prayer alarms.
  ///
  /// Android only, native by default, with two ways back to the plugin: the
  /// user's escape-hatch setting, and a bridge that does not answer. Both paths
  /// purge the native table on the way out — a committed native plan stays
  /// armed until something explicitly takes it back, and leaving it armed
  /// underneath a plugin schedule would sound every adhan twice.
  Future<void> _resolveAlarmOwner() async {
    if (!Platform.isAndroid) return;

    const bridge = MethodChannelAlarmBridge();
    const native = NativePrayerAlarmGateway(bridge);

    bool disabledByUser = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      disabledByUser =
          prefs.getBool(AppConstants.nativePrayerAlarmsDisabledKey) ?? false;
    } catch (e) {
      // A prefs failure must not decide something this important by accident.
      debugPrint('Could not read the native-alarm setting, assuming on: $e');
    }

    final available = await bridge.isAvailable();

    if (disabledByUser || !available) {
      if (available) {
        // Only reachable when the user turned it off. Hand the schedule back to
        // the plugin cleanly.
        try {
          await native.abandon();
        } catch (e) {
          debugPrint('Could not purge the native alarm table: $e');
        }
      }
      debugPrint(
        disabledByUser
            ? '🔔 Native prayer alarms disabled by setting'
            : '🔔 No native alarm bridge; staying on awesome_notifications',
      );
      return;
    }

    // Take the plugin's prayer schedules back BEFORE the native side arms the
    // same instants.
    //
    // An install upgrading from a build that used the plugin still has up to
    // twelve days of prayer notifications persisted inside
    // awesome_notifications, and the plugin's own MY_PACKAGE_REPLACED receiver
    // re-arms them without any app process. Without this sweep both owners hold
    // the same prayers and every adhan fires twice for a week after the update.
    // The same applies to a device coming back from the escape hatch, or from a
    // session that degraded and armed the plugin.
    try {
      await cancelIds(PrayerSchedulePlanner.cancellableIds);
    } catch (e) {
      debugPrint('Could not sweep the plugin before native takeover: $e');
    }

    _scheduler = PrayerScheduler(
      FallbackPrayerAlarmGateway(
        native,
        this,
        onDegraded: (error, _) {
          // The plugin cannot carry a sixty-day plan: its cancel sweep only
          // reaches [PrayerSchedulePlanner.cancelDayWindow] days of ids, so
          // anything beyond that would be armed and never cancellable. Saying
          // so here shrinks the horizon the cubit computes from the next
          // reschedule onward.
          _usesNativeAlarms = false;
          debugPrint('🔔 Native alarms degraded to the plugin: $error');
        },
      ),
      const PrayerSchedulePlanner(),
      _clock,
    );
    _usesNativeAlarms = true;
    debugPrint('🔔 Prayer alarms owned by native AlarmManager');
  }

  @override
  Future<bool> requestPermissions() async {
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      return await AwesomeNotifications()
          .requestPermissionToSendNotifications();
    }
    return true;
  }

  @override
  Future<bool> hasPermissions() async {
    return await AwesomeNotifications().isNotificationAllowed();
  }

  /// Schedule a single occurrence, today.
  ///
  /// Two callers, and they want different things:
  ///   * a real prayer, which must land on the id the planner would give it so
  ///     a later reschedule can cancel it;
  ///   * the Settings screen's "does this work?" probe, which is not a prayer
  ///     at all.
  ///
  /// The probe used to resolve through the prayer-name id map, whose
  /// `default:` arm returned **0** — an id outside the documented 100..214
  /// window that [cancelPrayerSchedules] never cleared, so a stray test
  /// notification could sit in the tray with nothing able to cancel it. It now
  /// gets [_testNotificationId] of its own.
  @override
  Future<void> schedulePrayerNotification({
    required String prayerName,
    required String prayerNameArabic,
    required DateTime prayerTime,
    required PrayerNotificationSettings settings,
    String? locationName,
  }) async {
    if (!settings.enabled) return;

    final prayer = PlannedPrayer.byKey(prayerName);
    if (prayer == null) {
      // The diagnostic probe: fires as soon as it is asked to, with no lead
      // time and no past-time check — the caller has already put it a couple
      // of seconds out precisely so the user sees it immediately.
      await _render(
        id: _testNotificationId,
        prayerName: prayerName,
        prayerNameArabic: prayerNameArabic,
        prayerTime: prayerTime,
        fireTime: prayerTime,
        leadTime: Duration.zero,
        isFajr: false,
        settings: settings,
        locationName: locationName,
      );
      return;
    }

    final fireTime = prayerTime.subtract(
      PrayerSchedulePlanner.leadTimeFor(settings.timing),
    );
    if (!fireTime.isAfter(_clock.now())) return;

    await _scheduleOne(
      PlannedPrayerNotification(
        id: PrayerSchedulePlanner.idFor(prayer, 0),
        prayer: prayer,
        day: DateTime(prayerTime.year, prayerTime.month, prayerTime.day),
        dayIndex: 0,
        prayerTime: prayerTime,
        fireTime: fireTime,
        settings: settings,
      ),
      locationName: locationName,
    );
  }

  /// Render one already-decided [PlannedPrayerNotification] into the plugin.
  ///
  /// Every decision — which id, which instant, whether it is still in the
  /// future, whether the prayer is enabled at all — was made by
  /// [PrayerSchedulePlanner]. This method deliberately makes none of them: a
  /// second opinion here is how the id map and the lead-time arithmetic
  /// drifted apart from the cubit's horizon logic in the first place.
  Future<void> _scheduleOne(
    PlannedPrayerNotification planned, {
    String? locationName,
  }) => _render(
    id: planned.id,
    prayerName: planned.prayer.key,
    prayerNameArabic: planned.prayer.arabicName,
    prayerTime: planned.prayerTime,
    fireTime: planned.fireTime,
    leadTime: planned.leadTime,
    isFajr: planned.prayer.isFajr,
    settings: planned.settings,
    locationName: locationName,
  );

  /// Turns one decision into an awesome_notifications request. Makes no
  /// scheduling decisions of its own — see [_scheduleOne].
  Future<void> _render({
    required int id,
    required String prayerName,
    required String prayerNameArabic,
    required DateTime prayerTime,
    required DateTime fireTime,
    required Duration leadTime,
    required bool isFajr,
    required PrayerNotificationSettings settings,
    String? locationName,
  }) async {
    final notificationTime = fireTime;
    final notificationId = id;

    // Arabic copy for the lead time, derived from the planned duration rather
    // than re-switching on the enum.
    final leadMinutes = leadTime.inMinutes;
    final timingText = leadMinutes == 0
        ? ''
        : (leadMinutes == 15 ? ' (بعد 15 دقيقة)' : ' (بعد $leadMinutes دقائق)');

    // Resolve the selected adhan → its per-sound channel (sound baked in), so
    // the correct adhan plays even when the app is dead. A null/unknown sound
    // (the "Default" option) falls back to the system-beep channel.
    final AdhanSoundOption? adhan = AdhanSounds.byAssetPath(
      settings.customSoundPath,
    );
    final bool useCustomAdhan = adhan?.androidRawRes != null;

    final String channelKey = useCustomAdhan
        ? 'adhan_${adhan!.key}_v1'
        : (isFajr ? _channelKeyFajrDefault : _channelKeyPrayersDefault);

    // Format time for display
    final String formattedTime = _formatTime(prayerTime);
    final String location = locationName ?? '';

    final content = NotificationContent(
      id: notificationId,
      channelKey: channelKey,
      groupKey: _channelGroupKey,
      title: '🕌 حان وقت صلاة $prayerNameArabic$timingText',
      body: '$formattedTime${location.isNotEmpty ? ' • $location' : ''}',
      notificationLayout: NotificationLayout.Default,
      payload: {
        'type': 'prayer',
        'prayer': prayerName,
        'time': prayerTime.toIso8601String(),
        // The moment the notification actually fires (= prayerTime minus any
        // "before X min" offset). The app-open replay guard compares against
        // THIS, not 'time', so a valid on-fire adhan isn't wrongly suppressed
        // when the user picked a before-prayer timing.
        'fireTime': notificationTime.toIso8601String(),
        'soundPath': settings.customSoundPath ?? '',
        'useCustomAdhan': useCustomAdhan.toString(),
      },
      wakeUpScreen: true,
      // iOS notification sound: the bundled ≤30s clip. awesome_notifications'
      // iOS resolver strips the "raw/" segment and looks for
      // "<androidRawRes>.aiff" in the app bundle (extension is hardcoded to
      // .aiff in IosAwnCore AudioUtils.getSoundFromResource), so the clips live
      // in ios/Runner/Sounds/*.aiff and are bundled with the Runner target. If a
      // clip is missing, iOS falls back to the default sound (notification still
      // shows) and the full adhan plays via the foreground Dart player. On
      // Android the sound comes from the per-sound channel, so this stays null.
      customSound: (Platform.isIOS && useCustomAdhan)
          ? 'resource://raw/${adhan!.androidRawRes}'
          : null,
      category: NotificationCategory.Reminder,
      // `criticalAlert: isFajr` used to sit here. awesome_notifications 0.12
      // removed it from NotificationContent — critical alerts are now declared
      // per-CHANNEL via NotificationChannel.criticalAlerts.
      //
      // Nothing is lost by dropping it, because it was already inert on BOTH
      // platforms:
      //   iOS     — needs the Apple-granted
      //             `com.apple.developer.usernotifications.critical-alerts`
      //             entitlement; ios/Runner/Runner.entitlements has only the
      //             App Group.
      //   Android — a channel only bypasses DND when
      //             NotificationManager.isNotificationPolicyAccessGranted() is
      //             true, which requires ACCESS_NOTIFICATION_POLICY (declared
      //             in neither this manifest nor the plugin's) AND an explicit
      //             user grant.
      //
      // It is deliberately NOT re-added at channel level here: the adhan
      // channels are keyed per SOUND (`adhan_<key>_v1`) and shared by all five
      // prayers, so setting criticalAlerts there would make every prayer a
      // critical alert, not just Fajr. Doing this properly needs a Fajr-specific
      // channel plus the permission opt-in flow.
    );
    // This button stops the adhan via the plugin's NATIVE dismiss path, not via
    // any Dart handler: DismissAction broadcasts to NotificationActionReceiver,
    // which calls StatusBarManager.dismissNotification -> NotificationManager
    // .cancel(id), and cancelling the notification that owns the in-flight
    // channel sound stops that sound. Best-effort: if another app's notification
    // chimes first it takes ownership of the sound slot, so the card is
    // cancelled but the audio may run on. A guaranteed stop needs
    // foreground-service playback instead of a channel sound.
    final actionButtons = [
      NotificationActionButton(
        key: 'STOP_ADHAN',
        label: 'إيقاف الأذان',
        actionType: ActionType.DismissAction,
      ),
    ];
    // Explicit-constructor form (fromDate doesn't expose timeZone) so we can
    // pass our pre-resolved IANA zone string and avoid the
    // TimeZone.getDefault() NPE on certain OEM Android builds.
    NotificationCalendar buildSchedule(bool precise) => NotificationCalendar(
      year: notificationTime.year,
      month: notificationTime.month,
      day: notificationTime.day,
      hour: notificationTime.hour,
      minute: notificationTime.minute,
      second: notificationTime.second,
      timeZone: _localTimeZone,
      allowWhileIdle: true,
      preciseAlarm: precise,
    );
    try {
      await AwesomeNotifications().createNotification(
        content: content,
        actionButtons: actionButtons,
        schedule: buildSchedule(true),
      );
    } catch (e) {
      // On Android 14+ exact alarms require SCHEDULE_EXACT_ALARM. If it isn't
      // granted, preciseAlarm scheduling throws — retry with an inexact (but
      // allowWhileIdle) schedule so the adhan is delayed, not dropped.
      debugPrint('Exact-alarm schedule failed, retrying inexact: $e');
      await AwesomeNotifications().createNotification(
        content: content,
        actionButtons: actionButtons,
        schedule: buildSchedule(false),
      );
    }
  }

  @override
  Future<void> scheduleAllPrayerNotifications({
    required Map<String, DateTime> prayerTimes,
    required NotificationSettingsModel settings,
    String? locationName,
  }) async {
    // Cancel all existing notifications first
    debugPrint('🔔 ═══════════════════════════════════════════════════');
    debugPrint('🔔 Starting notification scheduling process');
    debugPrint('🔔 ═══════════════════════════════════════════════════');

    await cancelAllNotifications();
    debugPrint('❌ Old notification schedules cancelled');

    if (!settings.masterEnabled) {
      debugPrint(
        '⚠️  Master notification toggle is OFF - no notifications scheduled',
      );
      debugPrint('🔔 ═══════════════════════════════════════════════════');
      return;
    }

    debugPrint('\n📅 Original Prayer Times:');
    prayerTimes.forEach((prayer, time) {
      debugPrint('   $prayer: $time');
    });

    final prayerSettings = {
      'Fajr': (settings.fajrSettings, 'الفجر'),
      'Dhuhr': (settings.dhuhrSettings, 'الظهر'),
      'Asr': (settings.asrSettings, 'العصر'),
      'Maghrib': (settings.maghribSettings, 'المغرب'),
      'Isha': (settings.ishaSettings, 'العشاء'),
    };

    debugPrint('\n⏰ Notification Times After Applying Settings:');

    for (final entry in prayerSettings.entries) {
      final prayerName = entry.key;
      final prayerSetting = entry.value.$1;
      final prayerNameArabic = entry.value.$2;
      final prayerTime = prayerTimes[prayerName];

      if (prayerTime != null) {
        // Calculate what the notification time will be
        DateTime notificationTime = prayerTime;
        String timingDescription = '';

        if (prayerSetting.enabled) {
          switch (prayerSetting.timing) {
            case NotificationTiming.before5Min:
              notificationTime = prayerTime.subtract(
                const Duration(minutes: 5),
              );
              timingDescription = ' (5 minutes before)';
              break;
            case NotificationTiming.before10Min:
              notificationTime = prayerTime.subtract(
                const Duration(minutes: 10),
              );
              timingDescription = ' (10 minutes before)';
              break;
            case NotificationTiming.before15Min:
              notificationTime = prayerTime.subtract(
                const Duration(minutes: 15),
              );
              timingDescription = ' (15 minutes before)';
              break;
            case NotificationTiming.onTime:
              timingDescription = ' (on time)';
              break;
          }

          if (notificationTime.isBefore(DateTime.now())) {
            debugPrint(
              '   ⏭️  $prayerName ($prayerNameArabic): SKIPPED (time has passed)',
            );
          } else {
            debugPrint(
              '   ✅ $prayerName ($prayerNameArabic): $notificationTime$timingDescription',
            );
          }
        } else {
          debugPrint('   ⚪ $prayerName ($prayerNameArabic): DISABLED');
        }

        await schedulePrayerNotification(
          prayerName: prayerName,
          prayerNameArabic: prayerNameArabic,
          prayerTime: prayerTime,
          settings: prayerSetting,
          locationName: locationName,
        );
      }
    }

    debugPrint('\n✅ Notification scheduling completed successfully');
    debugPrint('🔔 ═══════════════════════════════════════════════════\n');
  }

  @override
  Future<void> scheduleMultiDayPrayerNotifications({
    required Map<DateTime, Map<String, DateTime>> prayerTimesByDay,
    required NotificationSettingsModel settings,
    String? locationName,
  }) async {
    // Cancel only the PRAYER notification ids, then re-arm — never a global
    // cancelAll(), which would also wipe azkar/wird/fasting/daily-inspiration
    // reminders (they schedule on the same plugin with different ids/channels
    // and only re-arm on their own settings change / cold start).
    // WHAT to schedule is decided by PrayerSchedulePlanner — a pure function
    // of the settings, the prayer times and the clock, tested on its own.
    // PrayerScheduler owns the sequencing (cancel the whole prayer id window,
    // then arm). Everything in THIS class is rendering: turning each decision
    // into an awesome_notifications payload. Keeping those apart is what makes
    // "which alarms would this app arm at 04:12 on a DST night?" an assertion
    // rather than a field report.
    //
    // force: this method is the explicit "reschedule now" entry point, and its
    // callers already suppress redundant work upstream. Skipping here on an
    // unchanged signature would also skip the cancel sweep, which is the one
    // thing a caller reaching for this method after a reboot actually wants.
    final result = await _scheduler.reschedule(
      prayerTimesByDay: prayerTimesByDay,
      settings: settings,
      locationName: locationName,
      force: true,
    );

    if (result.isEmpty) {
      debugPrint(
        settings.masterEnabled
            ? '⚠️  Nothing left to schedule in the horizon'
            : '⚠️  Master notification toggle OFF — nothing scheduled',
      );
      return;
    }

    debugPrint(
      '✅ Scheduled ${result.planned.length} prayer notification(s) '
      'across ${result.dayCount} day(s)',
    );
    // The exact ids that were armed, not a day count. The diagnostic used to
    // take a count and walk `day < expectedDays`, which assumes the armed ids
    // are a contiguous prefix — false as soon as any prayer is disabled, any
    // day is missing from the horizon, or a past prayer is skipped. It then
    // reported ids as "evicted by iOS" that were never scheduled in the first
    // place.
    await debugAssertPrayerSchedulesSurvived(
      result.planned.map((p) => p.id).toList(),
    );
  }

  /// Cancel only the multi-day prayer notification ids (base 100–104 +
  /// dayIndex*10, i.e. 100–214), leaving every other feature's reminders
  /// untouched. Covers a generous day range so no stale prayer alarm survives a
  /// horizon change.
  ///
  /// The 100–214 window is safe: every other feature schedules well clear of it
  /// (persistent 999, fasting 5001–5999, wird 6001/6099, azkar 7100+).
  @override
  Future<void> cancelPrayerSchedules() async {
    // BOTH owners, unconditionally, and never only "the active one".
    //
    // Which gateway holds the schedule is decided once per launch and can
    // differ from the launch that armed it — an upgrade, the escape hatch being
    // flipped, a session that degraded. This is the path behind "turn the adhan
    // off", and asking the wrong owner means the app keeps calling the adhan
    // after the user told it to stop. On the native path that is up to sixty
    // days of it.
    await cancelIds(PrayerSchedulePlanner.cancellableIds);
    await _purgeNativeAlarms();
    // The next reschedule must actually re-arm: the OS table is now empty, so
    // an unchanged plan is no longer an unchanged reality.
    _scheduler.invalidate();
  }

  /// Takes back everything the native bridge has armed, if there is one.
  ///
  /// Safe to call on iOS, on a build without the Kotlin side, and when the
  /// native path was never active — the bridge either is not there or has an
  /// empty ledger.
  Future<void> _purgeNativeAlarms() async {
    if (!Platform.isAndroid) return;
    try {
      await const NativePrayerAlarmGateway(
        MethodChannelAlarmBridge(),
      ).abandon();
    } catch (e) {
      debugPrint('Could not purge the native alarm table: $e');
    }
  }

  /// Debug-only: verify iOS actually KEPT every prayer notification we asked for.
  ///
  /// iOS holds at most 64 pending notification requests and silently discards
  /// the rest — the plugin surfaces no error at the limit, so an over-budget app
  /// looks perfectly healthy right up until the adhan doesn't fire. This reads
  /// back what iOS really retained and screams in debug if a prayer id is gone
  /// or we are creeping toward the cap.
  ///
  /// Deliberately assert-only: never throw in release. A notification budget
  /// problem must not become a crash in front of a user.
  Future<void> debugAssertPrayerSchedulesSurvived(List<int> expectedIds) async {
    if (!kDebugMode || !Platform.isIOS) return;
    try {
      final pending = await AwesomeNotifications().listScheduledNotifications();
      final ids = pending.map((n) => n.content?.id).whereType<int>().toSet();
      final missing = expectedIds.where((id) => !ids.contains(id)).toList();
      debugPrint('🔔 iOS pending notifications: ${pending.length}/64');
      assert(
        pending.length <= 55,
        'iOS pending=${pending.length} (>55) — approaching the 64 cap; '
        'iOS will start silently dropping notifications.',
      );
      assert(
        missing.isEmpty,
        'PRAYER NOTIFICATIONS EVICTED BY iOS: $missing '
        '(total pending=${pending.length}/64).',
      );
    } catch (e) {
      debugPrint('🔔 debugAssertPrayerSchedulesSurvived skipped: $e');
    }
  }

  @override
  Future<void> cancelPrayerNotification(String prayerName) async {
    // Only today's occurrence. A caller that means "stop the adhan entirely"
    // wants cancelPrayerSchedules(), which sweeps the whole id window.
    final prayer = PlannedPrayer.byKey(prayerName);
    await AwesomeNotifications().cancel(
      prayer == null
          ? _testNotificationId
          : PrayerSchedulePlanner.idFor(prayer, 0),
    );
  }

  @override
  Future<void> cancelAllNotifications() async {
    await AwesomeNotifications().cancelAll();
    // The plugin's cancelAll reaches only the plugin. Prayer alarms may be
    // owned by the native bridge instead, and "cancel everything" leaving the
    // adhan ringing for the next sixty days is the worst possible reading of
    // this method's name.
    await _purgeNativeAlarms();
    _scheduler.invalidate();
  }

  @override
  Future<bool> hasActiveNotifications() async {
    final scheduledNotifications = await AwesomeNotifications()
        .listScheduledNotifications();
    return scheduledNotifications.isNotEmpty;
  }

  @override
  Future<List<int>> getScheduledNotificationIds() async {
    final scheduledNotifications = await AwesomeNotifications()
        .listScheduledNotifications();
    return scheduledNotifications.map((n) => n.content!.id!).toList();
  }

  // Helper method to format time for display
  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'مساءً' : 'صباحاً';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  @override
  Future<void> showPersistentNotification({
    required String nextPrayerName,
    required String nextPrayerNameArabic,
    required DateTime nextPrayerTime,
    String? locationName,
  }) async {
    final now = DateTime.now();
    final difference = nextPrayerTime.difference(now);

    // Format time remaining with seconds for better accuracy
    String timeRemaining = '';
    if (difference.inDays > 0) {
      // More than a day (Fajr tomorrow case)
      final hours = difference.inHours.remainder(24);
      final minutes = difference.inMinutes.remainder(60);
      timeRemaining = '${difference.inDays} يوم و $hours ساعة و $minutes دقيقة';
    } else if (difference.inHours > 0) {
      final hours = difference.inHours;
      final minutes = difference.inMinutes.remainder(60);
      final seconds = difference.inSeconds.remainder(60);
      timeRemaining = '$hours ساعة، $minutes دقيقة، $seconds ثانية';
    } else if (difference.inMinutes > 0) {
      final minutes = difference.inMinutes;
      final seconds = difference.inSeconds.remainder(60);
      timeRemaining = '$minutes دقيقة و $seconds ثانية';
    } else if (difference.inSeconds > 0) {
      final seconds = difference.inSeconds;
      timeRemaining = '$seconds ثانية';
    } else {
      timeRemaining = 'الآن';
    }

    final formattedTime = _formatTime(nextPrayerTime);
    final locationText = locationName != null && locationName.isNotEmpty
        ? '\n📍 $locationName'
        : '';

    // Enhanced notification body with emoji-enhanced formatting
    final String notificationBody =
        '''⏰ الموعد
$formattedTime

⏳ الوقت المتبقي
$timeRemaining$locationText''';

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: _persistentId,
        channelKey: _channelKeyPersistent,
        title: '🕌 الصلاة القادمة: $nextPrayerNameArabic',
        body: notificationBody,
        notificationLayout: NotificationLayout.BigText,
        category: NotificationCategory.Reminder,
        autoDismissible: false,
        locked: true,
        displayOnForeground: true,
        displayOnBackground: true,
        backgroundColor: const Color(0xFF20497D),
        color: Colors.white,
        icon: 'resource://mipmap/launcher_icon',
        largeIcon: 'resource://mipmap/launcher_icon',
        summary: timeRemaining,
        ticker: 'الصلاة القادمة: $nextPrayerNameArabic - $timeRemaining',
        showWhen: true,
        customSound: null,
        // `criticalAlert: false` removed — the parameter no longer exists on
        // NotificationContent in awesome_notifications 0.12 (see the prayer
        // notification above). It was explicitly false here anyway, which is
        // also the default, so this is a pure no-op removal.
      ),
    );
  }

  @override
  Future<void> hidePersistentNotification() async {
    await AwesomeNotifications().cancel(_persistentId);
  }
}
