import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/core/notifications/ios_notification_budget.dart';
import 'package:wadhakir/core/reminders/oem_autostart.dart';
import 'package:wadhakir/core/reminders/reminder_health.dart';
import 'package:wadhakir/core/reminders/reminder_ledger.dart';
import 'package:wadhakir/core/reminders/reminder_platform_probe.dart';
import 'package:wadhakir/core/utils/alarm_permission_helper.dart';
import 'package:wadhakir/features/pray_times/services/prayer_notification_content.dart';
import 'package:wadhakir/features/pray_times/services/prayer_notification_service.dart';
import 'package:wadhakir/features/settings/cubit/settings_cubit.dart';
import 'package:wadhakir/features/settings/cubit/settings_state.dart';

/// «هل تصل تذكيراتك؟» — one calm sentence, and at most one thing to press.
///
/// ## What this screen refuses to be
///
/// It does not show the ledger. The owner's decision on #15 was explicit: the
/// objection is to *showing* a tally, not to *having* one. A miss-counter on
/// screen turns a companion into a scorekeeper, which `PRODUCT.md` forbids in
/// as many words — and it would put the app's own failures in front of someone
/// who came here worried about their prayers.
///
/// So the 2,000 rows become one sentence, one button and one line of context.
/// The rows themselves leave the device only inside the user's own backup file,
/// where a support conversation can reach them.
///
/// ## Why the battery prompt is only here
///
/// R1 fixed a bug where the battery-optimisation dialog recorded "asked" before
/// the user had answered, making the fix inert for every existing install. The
/// lesson taken from it was bigger than the flag: this prompt is a demand for a
/// system-level exemption, and asking for it at onboarding — before the app has
/// any evidence it needs one — is how an app teaches users to say no. It is
/// offered here, from an explicit tap, and only once [ReminderHealth] has read
/// evidence that something is actually being killed.
class ReminderHealthScreen extends StatefulWidget {
  const ReminderHealthScreen({super.key, this.oemBridge, this.platformProbe});

  /// Injectable so a widget test can drive the no-button path without a device.
  final OemAutostartBridge? oemBridge;

  /// Injectable for the same reason — the live channel probe is a platform
  /// channel, and a test has none.
  final ReminderPlatformProbe? platformProbe;

  static Future<void> push(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const ReminderHealthScreen()));

  @override
  State<ReminderHealthScreen> createState() => _ReminderHealthScreenState();
}

class _ReminderHealthScreenState extends State<ReminderHealthScreen>
    with WidgetsBindingObserver {
  ReminderHealthVerdict? _verdict;
  String? _oemVendorKey;

  /// Which adhan channel the OS is blocking, so the button opens that one and
  /// not the other, healthy one.
  String? _blockedChannelKey;

  bool _loading = true;

  late final OemAutostartBridge _oem =
      widget.oemBridge ??
      (Platform.isAndroid
          ? const MethodChannelOemAutostart()
          : const NullOemAutostartBridge());

  late final ReminderPlatformProbe _probe =
      widget.platformProbe ??
      (Platform.isAndroid
          ? const MethodChannelReminderPlatformProbe()
          : const NullReminderPlatformProbe());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Every action on this screen hands the user to a system settings page, and
  /// the whole point is that they come back having changed something. A verdict
  /// that still says "notifications are blocked" after they have just unblocked
  /// them is a screen nobody trusts twice.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    // Guards two callers landing together: the lifecycle observer fires on
    // every resume, and `_perform` reloads after an action that may itself have
    // left and re-entered the app. Two concurrent loads would race to setState
    // with probes read at different instants.
    if (_loadInFlight) return;
    _loadInFlight = true;
    try {
      await _loadOnce();
    } finally {
      _loadInFlight = false;
    }
  }

  bool _loadInFlight = false;

  Future<void> _loadOnce() async {
    // Read before the first await, and only from a mounted State. `_perform`
    // resumes here after the user has been away in a system settings page, and
    // they may have popped this screen on the way back.
    if (!mounted) return;
    final settingsState = context.read<SettingsCubit>().state;
    final loaded = settingsState is SettingsLoaded;

    final entries = await ReminderLedger.instance.read();
    final vendorKey = await _oem.resolveKey();

    // Every one of these is read live. They can all be changed from outside the
    // app while it sits in the background, so a cached copy is a screen that is
    // confidently wrong.
    final notificationsAllowed = await _isNotificationAllowed();
    final exactAlarmsAllowed =
        await AlarmPermissionHelper.canScheduleExactAlarms();
    final batteryExempt = await _isBatteryExempt();
    final blockedChannel = await _probe.blockedChannel(const [
      PrayerNotificationContent.adhanChannelKey,
      PrayerNotificationContent.fajrAdhanChannelKey,
    ]);
    final pending = await _pendingCount();

    if (!mounted) return;
    setState(() {
      _oemVendorKey = vendorKey;
      _blockedChannelKey = blockedChannel;
      _verdict = ReminderHealth.evaluate(
        entries: entries,
        probe: ReminderHealthProbe(
          notificationsAllowed: notificationsAllowed,
          remindersEnabled:
              loaded &&
              settingsState.settings.notificationSettings.masterEnabled,
          // A settings box that failed to load must not be read as "reminders
          // are on". Assuming that would let this screen diagnose — and demand
          // permissions for — a feature the user had switched off.
          settingsKnown: loaded,
          exactAlarmsAllowed: exactAlarmsAllowed,
          batteryExempt: batteryExempt,
          oemAutostartAvailable: vendorKey != null,
          mutedAdhanChannelKey: blockedChannel,
          pendingCount: pending,
          pendingCapacity: Platform.isIOS
              ? IosNotificationBudget.pendingCap
              : null,
        ),
        now: DateTime.now(),
      );
      _loading = false;
    });
  }

  /// How many scheduled notifications iOS still holds.
  ///
  /// iOS only: it caps pending requests at 64 and silently drops the overflow,
  /// and it offers no delivery callback at all, so this number is the entire
  /// diagnosis available on that platform. On Android the same call reports
  /// only the plugin's schedules, which exclude the five prayers once native
  /// alarms own them — a number that would read as catastrophic loss when
  /// nothing is wrong.
  Future<int?> _pendingCount() async {
    if (!Platform.isIOS) return null;
    try {
      final ids = await PrayerNotificationService().getScheduledNotifications();
      return ids.length;
    } catch (_) {
      return null;
    }
  }

  Future<bool> _isNotificationAllowed() async {
    try {
      return await AwesomeNotifications().isNotificationAllowed();
    } catch (_) {
      // Assume allowed rather than accusing the OS of blocking us on the
      // strength of a failed probe. A wrong "broken" here sends the user to
      // change a setting that was never the problem.
      return true;
    }
  }

  Future<bool> _isBatteryExempt() async {
    if (!Platform.isAndroid) return true;
    try {
      return await Permission.ignoreBatteryOptimizations.isGranted;
    } catch (_) {
      return true;
    }
  }

  // --- the one button ------------------------------------------------------

  Future<void> _perform(ReminderHealthAction action) async {
    switch (action) {
      case ReminderHealthAction.openNotificationSettings:
        await AwesomeNotifications().showNotificationConfigPage();
      case ReminderHealthAction.openChannelSettings:
        // Straight to the channel the probe found blocked — not to the app's
        // notification list, and not to whichever adhan channel happens to be
        // first. There are two, «الأذان» and «أذان الفجر»: someone who muted
        // Fajr and is handed the other one sees a channel with nothing wrong,
        // changes nothing, comes back, and gets the same verdict.
        await AwesomeNotifications().showNotificationConfigPage(
          channelKey:
              _blockedChannelKey ?? PrayerNotificationContent.adhanChannelKey,
        );
      case ReminderHealthAction.grantExactAlarms:
        if (!mounted) return;
        await AlarmPermissionHelper.requestExactAlarmPermission(context);
      case ReminderHealthAction.openOemAutostart:
        final opened = await _oem.open();
        if (!opened && mounted) {
          // The probe found it when the screen was built and cannot open it
          // now — the vendor's own app was disabled in between. Say so instead
          // of leaving a button that appears to do nothing.
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.l10n?.translate('reminder_health.oem_failed') ??
                    'تعذّر فتح إعدادات الجهاز.',
              ),
            ),
          );
        }
      case ReminderHealthAction.grantBatteryExemption:
        if (!mounted) return;
        // The same helper the rest of the app uses, so the explanation the user
        // reads before the system dialog is the one they have seen before. It
        // also owns `battery_opt_granted` — the key R1 had to add after the
        // original recorded "asked" before the user had answered.
        await AlarmPermissionHelper.requestIgnoreBatteryOptimizations(context);
      case ReminderHealthAction.none:
        return;
    }
    // Whatever they did, re-read. didChangeAppLifecycleState covers the cases
    // that leave the app; this covers the ones that do not.
    await _load();
  }

  /// `translate` with a fallback that actually fires.
  ///
  /// `AppLocalizations.translate` returns the **key itself** on a miss, so the
  /// `?? fallback` idiom used across this app only covers a null `l10n` — never
  /// a missing key. That is harmless where the key is a literal somebody can
  /// grep for, and not harmless here: the OEM label key is built at runtime
  /// from a vendor name that lives in Kotlin, so adding a vendor natively
  /// without touching `ar.json` would put a raw `reminder_health.oem.<vendor>`
  /// on a button.
  static String _tr(AppLocalizations? l10n, String key, String fallback) {
    final translated = l10n?.translate(key);
    if (translated == null || translated == key) return fallback;
    return translated;
  }

  String _actionLabel(BuildContext context, ReminderHealthAction action) {
    final l10n = context.l10n;
    String tr(String key, String fallback) => _tr(l10n, key, fallback);

    switch (action) {
      case ReminderHealthAction.openNotificationSettings:
        return tr(
          'reminder_health.action.notifications',
          'فتح إعدادات الإشعارات',
        );
      case ReminderHealthAction.openChannelSettings:
        return tr('reminder_health.action.channel', 'فتح إعدادات قناة الأذان');
      case ReminderHealthAction.grantExactAlarms:
        return tr(
          'reminder_health.action.exact_alarms',
          'السماح بالمنبّهات الدقيقة',
        );
      case ReminderHealthAction.openOemAutostart:
        final key = _oemVendorKey;
        if (key == null) {
          return tr('reminder_health.action.oem', 'فتح إعدادات الجهاز');
        }
        return tr(
          OemAutostartLabels.keyFor(key),
          OemAutostartLabels.fallbackFor(key),
        );
      case ReminderHealthAction.grantBatteryExemption:
        return tr(
          'reminder_health.action.battery',
          'استثناء التطبيق من توفير البطارية',
        );
      case ReminderHealthAction.none:
        return '';
    }
  }

  // --- rendering -----------------------------------------------------------

  (IconData, Color) _face(ThemeData theme, ReminderHealthStatus status) =>
      switch (status) {
        ReminderHealthStatus.healthy => (
          Icons.check_circle_outline,
          theme.colorScheme.primary,
        ),
        ReminderHealthStatus.degraded => (
          Icons.schedule_outlined,
          theme.colorScheme.tertiary,
        ),
        ReminderHealthStatus.broken => (
          Icons.error_outline,
          theme.colorScheme.error,
        ),
        ReminderHealthStatus.off => (
          Icons.notifications_off_outlined,
          theme.colorScheme.onSurfaceVariant,
        ),
        ReminderHealthStatus.unknown => (
          Icons.hourglass_empty,
          theme.colorScheme.onSurfaceVariant,
        ),
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final verdict = _verdict;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n?.translate('reminder_health.title') ?? 'هل تصل تذكيراتك؟',
        ),
      ),
      body: _loading || verdict == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              children: [
                _verdictCard(theme, l10n, verdict),
                if (verdict.action != ReminderHealthAction.none) ...[
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => _perform(verdict.action),
                    child: Text(_actionLabel(context, verdict.action)),
                  ),
                ],
                const SizedBox(height: 28),
                _footnote(theme, l10n, verdict),
              ],
            ),
    );
  }

  Widget _verdictCard(
    ThemeData theme,
    AppLocalizations? l10n,
    ReminderHealthVerdict verdict,
  ) {
    final (icon, colour) = _face(theme, verdict.status);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: colour, size: 28),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            l10n?.translate(verdict.messageKey) ?? verdict.fallback,
            style: theme.textTheme.titleMedium?.copyWith(
              height: 1.6,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// How far back the verdict actually looked.
  ///
  /// Reads `evidence.since` rather than naming the window, because they are not
  /// the same thing: a device installed yesterday has one day of evidence, and
  /// a line saying «آخر أسبوعين» over it makes a fortnight-strength claim off a
  /// single row. On a screen whose entire job is to be believable, that is the
  /// kind of small lie that costs the whole thing.
  String _spanLine(AppLocalizations? l10n, ReminderHealthVerdict verdict) {
    final since = verdict.evidence.since;
    if (verdict.evidence.isEmpty || since == null) {
      return _tr(
        l10n,
        'reminder_health.note.no_evidence',
        'يبدأ التطبيق في ملاحظة تنبيهاتك من أول تنبيه يصلك.',
      );
    }

    final days = DateTime.now().toUtc().difference(since).inDays;
    if (days < 1) {
      return _tr(
        l10n,
        'reminder_health.note.window_today',
        'هذه القراءة مبنيّة على تنبيهات اليوم فقط على هذا الجهاز.',
      );
    }
    final template = _tr(
      l10n,
      'reminder_health.note.window_days',
      'هذه القراءة مبنيّة على تنبيهات آخر {days} يومًا على هذا الجهاز.',
    );
    // The localisation layer has no interpolation and no plurals — one token,
    // substituted here, exactly as `PrayerAlarmStore.setPersistentConfig`
    // handles `{prayer}`.
    return template.replaceAll('{days}', '$days');
  }

  /// The quiet line under the verdict.
  ///
  /// Says what the verdict was read from, and never how many reminders were
  /// missed. "Based on the last N days" is context a user can weigh;
  /// "you missed 3 prayers" is a scoreboard, and the app does not keep one.
  Widget _footnote(
    ThemeData theme,
    AppLocalizations? l10n,
    ReminderHealthVerdict verdict,
  ) {
    final style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      height: 1.7,
    );

    final lines = <String>[
      _spanLine(l10n, verdict),
      _tr(
        l10n,
        'reminder_health.note.private',
        'كل هذا محفوظ على جهازك وحده، ولا يُرسل إلى أي مكان. '
            'يسافر مع نسختك الاحتياطية إن أخذت واحدة.',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines) ...[
          Text(line, style: style),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}
