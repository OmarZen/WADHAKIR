import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:syncfusion_flutter_core/core.dart';
import 'package:wadhakir/data/models/fasting/fasting_reminder_settings_model.dart';
import 'package:wadhakir/data/models/fasting/islamic_fasting_day_model.dart';
import 'package:wadhakir/domain/repositories/prayer_times_repository.dart';
import 'package:wadhakir/features/fasting_reminders/services/hijri_date_calculator_service.dart';

/// Service for managing fasting reminder notifications
class FastingNotificationService {
  static final FastingNotificationService _instance =
      FastingNotificationService._internal();

  factory FastingNotificationService() => _instance;

  FastingNotificationService._internal();

  final HijriDateCalculatorService _hijriCalculator =
      HijriDateCalculatorService();

  // Prayer times repository for getting Maghrib and Fajr times
  PrayerTimesRepository? _prayerTimesRepository;

  /// Set prayer times repository for prayer-based reminder times
  void setPrayerTimesRepository(PrayerTimesRepository repository) {
    _prayerTimesRepository = repository;
    log('✅ ═══════════════════════════════════════════════════');
    log('✅ PRAYER TIMES REPOSITORY INJECTED SUCCESSFULLY');
    log('✅ Repository instance: ${repository.runtimeType}');
    log('✅ Repository is null: ${_prayerTimesRepository == null}');
    log('✅ ═══════════════════════════════════════════════════');
  }

  // Notification channel key for fasting reminders
  static const String _channelKey = 'fasting_reminders_channel';
  static const String _channelName = 'Fasting Reminders';
  static const String _channelDescription =
      'Notifications for voluntary fasting days';

  // Notification ID ranges (to avoid conflicts with prayer notifications)
  static const int _ayyamAlBidId = 5001;
  static const int _ninthTenthId = 5002;
  static const int _ashuraId = 5003;
  static const int _tasuaId = 5004;
  static const int _arafahId = 5005;
  // Weekly fasting notification IDs
  static const int _mondayFastingId = 5100;
  static const int _thursdayFastingId = 5101;
  // Reserved for future use:
  // static const int _eveReminderId = 5200;
  // static const int _morningReminderId = 5300;

  // Cached local timezone — see notification_repository_impl.dart for the
  // rationale. Some OEM Android builds NPE when the plugin tries to read
  // TimeZone.getDefault() on the Java side, so we resolve it once and pass
  // it explicitly to every NotificationCalendar.
  String _localTimeZone = 'UTC';

  // Once initialize() succeeds (or fails in a recoverable way) we don't
  // run it again. Re-running setChannel on every toggle hit a known
  // awesome_notifications 0.11.0 bug (see initialize() for details).
  bool _initialized = false;

  Future<String> _resolveTimeZone() async {
    try {
      final tz = await AwesomeNotifications().getLocalTimeZoneIdentifier();
      if (tz.isNotEmpty) return tz;
    } catch (_) {}
    final offset = DateTime.now().timeZoneOffset;
    final hours = offset.inHours;
    return hours == 0 ? 'UTC' : 'Etc/GMT${hours > 0 ? '-' : '+'}${hours.abs()}';
  }

  /// Initialize the notification channel.
  ///
  /// Idempotent — guarded by `_initialized` so we don't re-run on every
  /// `scheduleAllFastingNotifications` call. Re-running matters because:
  ///
  /// 1. `setChannel(forceUpdate: true)` hits a known
  ///    awesome_notifications 0.11.0 bug: when the Android-side channel
  ///    already exists, `ChannelManager.androidChannelNeedsForceUpdate`
  ///    throws `ArrayIndexOutOfBoundsException: length=3; index=-1000`
  ///    while trying to read the existing channel's visibility/importance
  ///    metadata. The throw bubbles up as a PlatformException on every
  ///    toggle.
  ///
  /// 2. We MUST NOT fall back to `AwesomeNotifications().initialize(...)`
  ///    here — `initialize` REPLACES the full channel set, which would
  ///    wipe out the prayer notification channels registered by
  ///    `notification_repository_impl.dart`. The prayer service's
  ///    `initialize()` includes a matching `fasting_reminders_channel`
  ///    entry, so as long as either service has run once the channel
  ///    exists.
  ///
  /// 3. If `setChannel` fails because the channel already exists, that's
  ///    fine — the channel is there. We swallow the error, mark the
  ///    service initialized, and move on. Subsequent calls are no-ops.
  Future<void> initialize() async {
    if (_initialized) {
      log(
        '🟢 FastingNotificationService.initialize: already initialized, skipping',
      );
      return;
    }
    final sw = Stopwatch()..start();
    log('🟢 FastingNotificationService.initialize: START');

    _localTimeZone = await _resolveTimeZone();
    log(
      '🟢 FastingNotificationService.initialize: timezone resolved = $_localTimeZone (${sw.elapsedMilliseconds}ms)',
    );

    try {
      // `forceUpdate: false` so we don't trigger the buggy needs-update
      // path when the channel already exists. setChannel still creates
      // the channel on first run.
      log(
        '🟢 FastingNotificationService.initialize: calling setChannel(channel=$_channelKey)',
      );
      await AwesomeNotifications().setChannel(
        NotificationChannel(
          channelKey: _channelKey,
          channelName: _channelName,
          channelDescription: _channelDescription,
          defaultColor: const Color(0xFF26A69A),
          ledColor: const Color(0xFFFFB74D),
          importance: NotificationImportance.High,
          channelShowBadge: true,
          playSound: true,
          enableVibration: true,
        ),
      );
      log('🟢 FastingNotificationService.initialize: setChannel OK');
    } catch (e) {
      // The error only fires when the channel already exists (the failing
      // codepath is `androidChannelNeedsForceUpdate` — it has to read an
      // existing channel to compare). Treat it as "already registered"
      // and continue. Do NOT call initialize() — see the docstring above.
      log(
        '🟡 FastingNotificationService.initialize: setChannel failed '
        '(channel likely already registered): $e',
      );
    } finally {
      _initialized = true;
      sw.stop();
      log(
        '🟢 FastingNotificationService.initialize: DONE in ${sw.elapsedMilliseconds}ms',
      );
    }
  }

  /// Schedule all fasting notifications based on settings
  Future<void> scheduleAllFastingNotifications(
    FastingReminderSettings settings,
  ) async {
    // Ensure the notification channel exists before we try to create any
    // notification against it. The cubit calls this method eagerly at app
    // start (lazy:false in main.dart) and the prayer service that ALSO
    // registers `fasting_reminders_channel` may not have run yet, so we
    // can't rely on it. `initialize()` uses `setChannel(forceUpdate:true)`
    // and is idempotent.
    await initialize();

    log('📅 ═══════════════════════════════════════════════════');
    log('📅 SCHEDULING ALL FASTING NOTIFICATIONS');
    log('📅 ═══════════════════════════════════════════════════');
    log('');
    log('⚙️  Settings Received:');
    log('   • Monthly Fasting: ${settings.monthlyFastingRemindersEnabled}');
    log('   • Monday Fasting: ${settings.mondayFastingEnabled}');
    log('   • Thursday Fasting: ${settings.thursdayFastingEnabled}');
    log('   • Ayyam al-Bid: ${settings.ayyamAlBidEnabled}');
    log('   • 9th & 10th: ${settings.ninthTenthEnabled}');
    log('   • Special Days: ${settings.specialDaysEmphasis}');
    log('   • Eve Reminder: ${settings.eveReminder}');
    log('   • Morning Reminder: ${settings.morningReminder}');
    log('   • Weekly Time: ${settings.weeklyNotificationTime}');
    log('   • Days Before: ${settings.daysBeforeNotification}');
    log('');

    // Cancel all existing fasting notifications first
    await cancelAllFastingNotifications();

    // Schedule weekly fasting (Monday/Thursday) if enabled
    await _scheduleWeeklyFastingNotifications(settings);

    // Schedule Hijri calendar fasting if enabled
    if (settings.monthlyFastingRemindersEnabled) {
      await _scheduleHijriCalendarNotifications(settings);
    } else {
      log(
        '⏭️  Monthly Hijri fasting reminders DISABLED, skipping Hijri scheduling',
      );
    }

    log('');
    log('✅ ═══════════════════════════════════════════════════');
    log('✅ ALL FASTING NOTIFICATIONS SCHEDULED SUCCESSFULLY!');
    log('✅ ═══════════════════════════════════════════════════');
    log('');
  }

  /// Schedule weekly fasting notifications (Monday/Thursday)
  Future<void> _scheduleWeeklyFastingNotifications(
    FastingReminderSettings settings,
  ) async {
    log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    log('📆 WEEKLY FASTING NOTIFICATIONS');
    log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    if (!settings.mondayFastingEnabled && !settings.thursdayFastingEnabled) {
      log('⏭️  Both Monday and Thursday DISABLED, skipping weekly scheduling');
      log('');
      return;
    }

    // Schedule Monday fasting
    if (settings.mondayFastingEnabled) {
      log('\n🔔 Scheduling MONDAY fasting notification...');
      await _scheduleWeeklyFastingDay(
        dayOfWeek: DateTime.monday,
        dayName: 'Monday',
        dayNameArabic: 'الإثنين',
        notificationId: _mondayFastingId,
        settings: settings,
      );
    } else {
      log('\n⏭️  Monday fasting DISABLED');
    }

    // Schedule Thursday fasting
    if (settings.thursdayFastingEnabled) {
      log('\n🔔 Scheduling THURSDAY fasting notification...');
      await _scheduleWeeklyFastingDay(
        dayOfWeek: DateTime.thursday,
        dayName: 'Thursday',
        dayNameArabic: 'الخميس',
        notificationId: _thursdayFastingId,
        settings: settings,
      );
    } else {
      log('\n⏭️  Thursday fasting DISABLED');
    }

    log('\n✅ Weekly fasting notifications scheduling complete');
    log('');
  }

  /// Schedule recurring notification for a specific weekday
  Future<void> _scheduleWeeklyFastingDay({
    required int dayOfWeek,
    required String dayName,
    required String dayNameArabic,
    required int notificationId,
    required FastingReminderSettings settings,
  }) async {
    // Parse notification time from settings
    final timeParts = settings.weeklyNotificationTime.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    // Calculate next occurrence of this weekday
    final now = DateTime.now();
    var nextOccurrence = _getNextWeekday(now, dayOfWeek);

    // If the time for today has already passed, move to next week
    if (nextOccurrence.day == now.day) {
      final notificationTime = DateTime(
        nextOccurrence.year,
        nextOccurrence.month,
        nextOccurrence.day,
        hour,
        minute,
      );
      if (notificationTime.isBefore(now)) {
        nextOccurrence = nextOccurrence.add(const Duration(days: 7));
      }
    }

    // Subtract 1 day to schedule the night before
    nextOccurrence = nextOccurrence.subtract(const Duration(days: 1));

    // Create notification time
    final scheduledDate = DateTime(
      nextOccurrence.year,
      nextOccurrence.month,
      nextOccurrence.day,
      hour,
      minute,
    );

    final weekdayForNotification = dayOfWeek == DateTime.monday
        ? 7
        : dayOfWeek - 1;

    log('   📋 Notification Details:');
    log('      • ID: $notificationId');
    log('      • Title: 🌙 تذكير بصيام $dayNameArabic');
    log('      • Body: غداً يوم $dayNameArabic، يُستحب الصيام');
    log('      • Scheduled Time: $scheduledDate');
    log(
      '      • Weekday: $weekdayForNotification (${_getWeekdayName(weekdayForNotification)})',
    );
    log('      • Hour: $hour, Minute: $minute');
    log('      • Repeats: WEEKLY');

    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notificationId,
          channelKey: _channelKey,
          title: '🌙 تذكير بصيام $dayNameArabic',
          body: 'غداً يوم $dayNameArabic، يُستحب الصيام',
          category: NotificationCategory.Reminder,
          wakeUpScreen: true,
          fullScreenIntent: false,
          autoDismissible: true,
          payload: {
            'type': 'weekly_fasting',
            'dayName': dayName,
            'dayOfWeek': dayOfWeek.toString(),
          },
        ),
        // MUST pass `timeZone` explicitly. Some OEM Android builds NPE in
        // `TimeZone.getDefault().getOffset(long)` on the Java side when
        // the plugin tries to resolve the device timezone itself
        // ("Attempt to invoke virtual method 'int java.util.TimeZone
        // .getOffset(long)' on a null object reference"). `_localTimeZone`
        // is the pre-resolved IANA id from initialize().
        schedule: NotificationCalendar(
          weekday: weekdayForNotification,
          hour: hour,
          minute: minute,
          second: 0,
          millisecond: 0,
          repeats: true,
          timeZone: _localTimeZone,
        ),
      );
      log('   ✅ Successfully scheduled $dayName recurring notification');
    } catch (e) {
      log('   ❌ ERROR scheduling $dayName notification: $e');
      rethrow;
    }
  }

  /// Get next occurrence of a specific weekday
  DateTime _getNextWeekday(DateTime from, int desiredWeekday) {
    final currentWeekday = from.weekday;
    int daysToAdd = (desiredWeekday - currentWeekday) % 7;
    if (daysToAdd <= 0) daysToAdd += 7;
    return DateTime(
      from.year,
      from.month,
      from.day,
    ).add(Duration(days: daysToAdd));
  }

  /// Get weekday name from weekday number (1=Monday, 7=Sunday)
  String _getWeekdayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Unknown';
    }
  }

  /// Schedule Hijri calendar fasting notifications
  Future<void> _scheduleHijriCalendarNotifications(
    FastingReminderSettings settings,
  ) async {
    log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    log('🌙 HIJRI CALENDAR FASTING NOTIFICATIONS');
    log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    final currentHijri = HijriDateTime.now();
    final currentMonth = currentHijri.month;
    final currentYear = currentHijri.year;

    log(
      '📆 Current Hijri Date: ${currentHijri.day}/$currentMonth/$currentYear',
    );
    log('');

    // Schedule notifications for this month
    log('📅 Scheduling for CURRENT month: $currentMonth/$currentYear');
    await _scheduleMonthNotifications(
      month: currentMonth,
      year: currentYear,
      settings: settings,
    );

    // Schedule notifications for next month
    final nextMonth = currentMonth == 12 ? 1 : currentMonth + 1;
    final nextYear = currentMonth == 12 ? currentYear + 1 : currentYear;
    log('\n📅 Scheduling for NEXT month: $nextMonth/$nextYear');
    await _scheduleMonthNotifications(
      month: nextMonth,
      year: nextYear,
      settings: settings,
    );

    log('\n✅ Hijri calendar notifications scheduling complete');
    log('');
  }

  /// Schedule notifications for a specific month
  Future<void> _scheduleMonthNotifications({
    required int month,
    required int year,
    required FastingReminderSettings settings,
  }) async {
    final currentHijri = HijriDateTime.now();
    int notificationCount = 0;

    // Helper function to check if notification should be scheduled
    bool shouldSchedule(int day) {
      final should =
          month != currentHijri.month ||
          year != currentHijri.year ||
          day >= currentHijri.day;
      if (!should) {
        log('   ⏭️  Skipping day $day (in the past)');
      }
      return should;
    }

    // Schedule Ayyam al-Bid (13, 14, 15)
    if (settings.ayyamAlBidEnabled) {
      log('\n   🌕 Scheduling Ayyam al-Bid (White Days)...');
      if (shouldSchedule(13)) {
        await _scheduleNotificationForDay(
          hijriYear: year,
          hijriMonth: month,
          hijriDay: 13,
          fastingDay: IslamicFastingDay.ayyamAlBid13(),
          settings: settings,
          notificationIdBase: _ayyamAlBidId + 130,
        );
        notificationCount++;
      }
      if (shouldSchedule(14)) {
        await _scheduleNotificationForDay(
          hijriYear: year,
          hijriMonth: month,
          hijriDay: 14,
          fastingDay: IslamicFastingDay.ayyamAlBid14(),
          settings: settings,
          notificationIdBase: _ayyamAlBidId + 140,
        );
        notificationCount++;
      }
      if (shouldSchedule(15)) {
        await _scheduleNotificationForDay(
          hijriYear: year,
          hijriMonth: month,
          hijriDay: 15,
          fastingDay: IslamicFastingDay.ayyamAlBid15(),
          settings: settings,
          notificationIdBase: _ayyamAlBidId + 150,
        );
        notificationCount++;
      }
    } else {
      log('\n   ⏭️  Ayyam al-Bid DISABLED');
    }

    // Schedule 9th and 10th
    if (settings.ninthTenthEnabled) {
      log('\n   📖 Scheduling 9th & 10th of the month...');
      if (shouldSchedule(9)) {
        await _scheduleNotificationForDay(
          hijriYear: year,
          hijriMonth: month,
          hijriDay: 9,
          fastingDay: IslamicFastingDay.ninthOfMonth(),
          settings: settings,
          notificationIdBase: _ninthTenthId + 90,
        );
        notificationCount++;
      }
      if (shouldSchedule(10)) {
        await _scheduleNotificationForDay(
          hijriYear: year,
          hijriMonth: month,
          hijriDay: 10,
          fastingDay: IslamicFastingDay.tenthOfMonth(),
          settings: settings,
          notificationIdBase: _ninthTenthId + 100,
        );
        notificationCount++;
      }
    } else {
      log('\n   ⏭️  9th & 10th DISABLED');
    }

    // Schedule special days with emphasis
    if (settings.specialDaysEmphasis) {
      log('\n   ⭐ Scheduling Special Days...');
      // Muharram special days
      if (month == 1) {
        log('      🕘 Muharram detected - scheduling Tasu\'a & Ashura');
        if (shouldSchedule(9)) {
          await _scheduleNotificationForDay(
            hijriYear: year,
            hijriMonth: month,
            hijriDay: 9,
            fastingDay: IslamicFastingDay.tasua(),
            settings: settings,
            notificationIdBase: _tasuaId,
            isSpecial: true,
          );
          notificationCount++;
        }
        if (shouldSchedule(10)) {
          await _scheduleNotificationForDay(
            hijriYear: year,
            hijriMonth: month,
            hijriDay: 10,
            fastingDay: IslamicFastingDay.ashura(),
            settings: settings,
            notificationIdBase: _ashuraId,
            isSpecial: true,
          );
          notificationCount++;
        }
      }

      // Dhul Hijjah - Arafah
      if (month == 12) {
        log('      🕙 Dhul Hijjah detected - scheduling Arafah');
        if (shouldSchedule(9)) {
          await _scheduleNotificationForDay(
            hijriYear: year,
            hijriMonth: month,
            hijriDay: 9,
            fastingDay: IslamicFastingDay.arafah(),
            settings: settings,
            notificationIdBase: _arafahId,
            isSpecial: true,
          );
          notificationCount++;
        }
      }
    } else {
      log('\n   ⏭️  Special Days DISABLED');
    }

    log(
      '\n   ✅ Month $month/$year: Scheduled $notificationCount fasting day(s)',
    );
  }

  /// Schedule notification for a specific day
  Future<void> _scheduleNotificationForDay({
    required int hijriYear,
    required int hijriMonth,
    required int hijriDay,
    required IslamicFastingDay fastingDay,
    required FastingReminderSettings settings,
    required int notificationIdBase,
    bool isSpecial = false,
  }) async {
    log(
      '      📅 ${fastingDay.nameEn} (${fastingDay.nameAr}) - $hijriDay/$hijriMonth/$hijriYear',
    );
    log(
      '         🔍 Prayer times repository status: ${_prayerTimesRepository == null ? "NULL ❌" : "AVAILABLE ✅"}',
    );

    // Get Gregorian date for this Hijri date
    final gregorianDate = _hijriCalculator.getGregorianFromHijri(
      year: hijriYear,
      month: hijriMonth,
      day: hijriDay,
    );

    log(
      '         ➡️  Gregorian: ${gregorianDate.day}/${gregorianDate.month}/${gregorianDate.year}',
    );

    // Skip if date is in the past
    if (gregorianDate.isBefore(DateTime.now())) {
      log('         ⏭️  Date is in the past, skipping');
      return;
    }

    int scheduledCount = 0;

    // Schedule eve reminder (night before) - uses Maghrib prayer time
    if (settings.eveReminder) {
      final eveDate = gregorianDate.subtract(const Duration(days: 1));

      try {
        // Get prayer times for the evening before fasting day
        DateTime? eveNotificationTime;

        if (_prayerTimesRepository != null) {
          // Get Maghrib time from prayer times
          final evePrayerTimes = await _prayerTimesRepository!.getPrayerTimes(
            date: eveDate,
          );

          // Use Maghrib time as reminder time
          eveNotificationTime = evePrayerTimes.maghrib;
          log(
            '         🕌 Using Maghrib prayer time: ${eveNotificationTime.hour}:${eveNotificationTime.minute.toString().padLeft(2, '0')}',
          );
        } else {
          // Fallback: Use settings time if prayer times repository not  available
          log(
            '         ⚠️  Prayer times repository not available, using settings time',
          );
          final eveTimeParts = settings.eveReminderTime.split(':');
          final eveHour = int.parse(eveTimeParts[0]);
          final eveMinute = int.parse(eveTimeParts[1]);

          eveNotificationTime = DateTime(
            eveDate.year,
            eveDate.month,
            eveDate.day,
            eveHour,
            eveMinute,
          );
        }

        if (eveNotificationTime.isAfter(DateTime.now())) {
          await _scheduleNotification(
            id: notificationIdBase + 1,
            title: _getNotificationTitle(
              fastingDay,
              isEve: true,
              isSpecial: isSpecial,
            ),
            body: _getNotificationBody(fastingDay, isEve: true),
            scheduledDate: eveNotificationTime,
            settings: settings,
            fastingDay: fastingDay,
          );
          scheduledCount++;
        }
      } catch (e, stackTrace) {
        log('         ❌ ERROR getting Maghrib time: $e');
        log('         📍 Stack trace: $stackTrace');
        log('         ⚠️  Skipping eve reminder due to error');
      }
    }

    // Schedule morning reminder - uses Fajr prayer time minus 5 minutes
    if (settings.morningReminder) {
      try {
        DateTime? morningNotificationTime;

        if (_prayerTimesRepository != null) {
          // Get Fajr time from prayer times
          final morningPrayerTimes = await _prayerTimesRepository!
              .getPrayerTimes(date: gregorianDate);

          // Use Fajr time minus 5 minutes as reminder time
          morningNotificationTime = morningPrayerTimes.fajr.subtract(
            const Duration(minutes: 5),
          );
          log(
            '         🕌 Using Fajr-5min prayer time: ${morningNotificationTime.hour}:${morningNotificationTime.minute.toString().padLeft(2, '0')}',
          );
        } else {
          // Fallback: Use settings time if prayer times repository not available
          log(
            '         ⚠️  Prayer times repository not available, using settings time',
          );
          final morningTimeParts = settings.morningReminderTime.split(':');
          final morningHour = int.parse(morningTimeParts[0]);
          final morningMinute = int.parse(morningTimeParts[1]);

          morningNotificationTime = DateTime(
            gregorianDate.year,
            gregorianDate.month,
            gregorianDate.day,
            morningHour,
            morningMinute,
          );
        }

        if (morningNotificationTime.isAfter(DateTime.now())) {
          await _scheduleNotification(
            id: notificationIdBase + 2,
            title: _getNotificationTitle(
              fastingDay,
              isEve: false,
              isSpecial: isSpecial,
            ),
            body: _getNotificationBody(fastingDay, isEve: false),
            scheduledDate: morningNotificationTime,
            settings: settings,
            fastingDay: fastingDay,
          );
          scheduledCount++;
        }
      } catch (e, stackTrace) {
        log('         ❌ ERROR getting Fajr time: $e');
        log('         📍 Stack trace: $stackTrace');
        log('         ⚠️  Skipping morning reminder due to error');
      }
    }

    // Schedule advance reminder (X days before)
    if (settings.daysBeforeNotification > 0) {
      final advanceDate = gregorianDate.subtract(
        Duration(days: settings.daysBeforeNotification),
      );

      // Parse advance reminder time from settings
      final advanceTimeParts = settings.advanceReminderTime.split(':');
      final advanceHour = int.parse(advanceTimeParts[0]);
      final advanceMinute = int.parse(advanceTimeParts[1]);

      final advanceNotificationTime = DateTime(
        advanceDate.year,
        advanceDate.month,
        advanceDate.day,
        advanceHour,
        advanceMinute,
      );

      if (advanceNotificationTime.isAfter(DateTime.now())) {
        await _scheduleNotification(
          id: notificationIdBase + 3,
          title: _getNotificationTitle(
            fastingDay,
            isAdvance: true,
            isSpecial: isSpecial,
          ),
          body: _getAdvanceNotificationBody(
            fastingDay,
            settings.daysBeforeNotification,
          ),
          scheduledDate: advanceNotificationTime,
          settings: settings,
          fastingDay: fastingDay,
        );
        scheduledCount++;
      }
    }

    log(
      '         ✅ Total notifications scheduled for this day: $scheduledCount',
    );
  }

  /// Schedule a single notification
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required FastingReminderSettings settings,
    required IslamicFastingDay fastingDay,
  }) async {
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: _channelKey,
          title: title,
          body: body,
          category: NotificationCategory.Reminder,
          wakeUpScreen: true,
          fullScreenIntent: false,
          autoDismissible: true,
          payload: {
            'type': 'fasting_reminder',
            'fastingDayName': fastingDay.nameEn,
            'hijriDay': fastingDay.hijriDay.toString(),
          },
        ),
        // Use the explicit constructor so we can pass our cached timezone
        // (fromDate doesn't expose timeZone, see notification_repository_impl).
        schedule: NotificationCalendar(
          year: scheduledDate.year,
          month: scheduledDate.month,
          day: scheduledDate.day,
          hour: scheduledDate.hour,
          minute: scheduledDate.minute,
          second: scheduledDate.second,
          timeZone: _localTimeZone,
        ),
      );

      log(
        '         ✅ Created notification #$id: "$title" @ ${scheduledDate.day}/${scheduledDate.month}/${scheduledDate.year} ${scheduledDate.hour}:${scheduledDate.minute.toString().padLeft(2, '0')}',
      );
    } catch (e) {
      log('         ❌ ERROR creating notification #$id: $e');
    }
  }

  /// Get notification title
  String _getNotificationTitle(
    IslamicFastingDay day, {
    bool isEve = false,
    bool isAdvance = false,
    bool isSpecial = false,
  }) {
    if (isSpecial) {
      return '🌙 تذكير بصيام ${day.nameAr}';
    }

    if (isAdvance) {
      return '📅 تذكير مسبق بالصيام المستحب';
    }

    if (isEve) {
      return '🌙 غداً يوم صيام مستحب';
    }

    return '🌙 تذكير بالصيام';
  }

  /// Get notification body
  String _getNotificationBody(IslamicFastingDay day, {bool isEve = false}) {
    if (isEve) {
      return 'غداً ${day.nameAr} (${day.descriptionAr})، يُستحب الصيام';
    }

    return 'اليوم ${day.nameAr}، لا تنس نية الصيام';
  }

  /// Get advance notification body
  String _getAdvanceNotificationBody(IslamicFastingDay day, int daysCount) {
    if (daysCount == 1) {
      return 'غداً ${day.nameAr}، استعد للصيام';
    }
    return 'بعد $daysCount أيام: ${day.nameAr}';
  }

  /// Cancel all fasting notifications.
  ///
  /// Uses the plugin's channel-scoped cancel APIs
  /// (`cancelNotificationsByChannelKey` + `cancelSchedulesByChannelKey`)
  /// — a single MethodChannel hop each, rather than the previous
  /// 1002-id-by-id loop which hit the MethodChannel 1002 times and could
  /// block the UI for several seconds on cold start (the cubit awaited
  /// this before emitting Loaded). Channel-scoped APIs only touch
  /// notifications/schedules tagged with our fasting channel, so prayer
  /// notifications are unaffected.
  Future<void> cancelAllFastingNotifications() async {
    final sw = Stopwatch()..start();
    log('🗑️  cancelAllFastingNotifications: start (channel=$_channelKey)');
    try {
      await AwesomeNotifications().cancelNotificationsByChannelKey(_channelKey);
      log(
        '🗑️  cancelAllFastingNotifications: displayed notifications cleared',
      );
    } catch (e) {
      log('🗑️  cancelNotificationsByChannelKey error (continuing): $e');
    }
    try {
      await AwesomeNotifications().cancelSchedulesByChannelKey(_channelKey);
      log(
        '🗑️  cancelAllFastingNotifications: scheduled notifications cleared',
      );
    } catch (e) {
      log('🗑️  cancelSchedulesByChannelKey error (continuing): $e');
    }
    sw.stop();
    log(
      '🗑️  cancelAllFastingNotifications: done in ${sw.elapsedMilliseconds}ms',
    );
  }

  /// Cancel weekly fasting notification for specific day
  Future<void> cancelWeeklyFastingNotification(String dayName) async {
    final notificationId = dayName.toLowerCase() == 'monday'
        ? _mondayFastingId
        : _thursdayFastingId;

    await AwesomeNotifications().cancel(notificationId);
    log('🗑️  Cancelled $dayName fasting notification #$notificationId');
  }

  /// Cancel notifications for a specific day type
  Future<void> cancelNotificationsForDayType(FastingDayType type) async {
    int baseId;
    String typeName;
    switch (type) {
      case FastingDayType.ayyamAlBid:
        baseId = _ayyamAlBidId;
        typeName = 'Ayyam al-Bid';
        break;
      case FastingDayType.ninthTenth:
        baseId = _ninthTenthId;
        typeName = '9th & 10th';
        break;
      case FastingDayType.special:
        baseId = _ashuraId;
        typeName = 'Special Days';
        break;
      case FastingDayType.weeklyFasting:
        baseId = _mondayFastingId;
        typeName = 'Weekly Fasting';
        break;
    }

    log(
      '🗑️  Cancelling $typeName notifications (ID range $baseId to ${baseId + 99})...',
    );
    for (int i = 0; i < 100; i++) {
      await AwesomeNotifications().cancel(baseId + i);
    }
    log('   ✅ Cancelled 100 notification IDs for $typeName');
  }

  /// Fire a single test fasting reminder right now so the user can confirm
  /// the channel + permission flow without waiting for a real fast day.
  /// Uses notification id 5999 (outside the real fasting id range so it
  /// never collides with scheduled reminders).
  Future<bool> sendTestNotification() async {
    try {
      // Make sure the channel exists; calling initialize() is idempotent.
      await initialize();

      final hasPermission = await AwesomeNotifications()
          .isNotificationAllowed();
      if (!hasPermission) {
        final granted = await AwesomeNotifications()
            .requestPermissionToSendNotifications();
        if (!granted) return false;
      }

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 5999,
          channelKey: _channelKey,
          title: '🌙 اختبار تذكير الصيام',
          body: 'هذا تنبيه تجريبي للتأكد من أن تذكيرات الصيام تعمل بشكل صحيح.',
          notificationLayout: NotificationLayout.Default,
          category: NotificationCategory.Reminder,
          wakeUpScreen: true,
        ),
      );
      return true;
    } catch (e) {
      log('sendTestNotification (fasting) error: $e');
      return false;
    }
  }
}
