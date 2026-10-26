import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/data/models/prayer_times_model.dart';
import 'package:wadhakir/features/app_lock/services/app_lock_hadith_quotes_service.dart';
import 'package:wadhakir/features/app_lock/services/app_lock_prayer_window.dart';

/// What the native lock monitor needs to start, built without a widget.
///
/// The settings screen used to be the only place that could build it, from
/// its own `context`. So when the monitor was gone and had no saved config to
/// restore from (an app update, a backup restore), nothing outside that
/// screen could start it again, and the lock stayed off while its switch said
/// on. Both the screen and the app's resume path build it here now.
class AppLockMonitorConfig {
  AppLockMonitorConfig._();

  static const String _defaultMessage =
      'Use this time in something beneficial.';

  /// The lock screen's texts, in the app's language.
  static Map<String, String> overlayTexts(
    AppLocalizations? l10n, {
    String? referenceText,
    String? prayerName,
  }) {
    return <String, String>{
      'title':
          l10n?.translate('settings.app_lock_overlay_title_text') ??
          'Valuable time',
      'reference': referenceText ?? '',
      'prayerName':
          prayerName ??
          (l10n?.translate('settings.app_lock_prayer_name_fallback') ??
              'Prayer time'),
      'goHome':
          l10n?.translate('settings.app_lock_overlay_go_home') ??
          'Return to home',
      'completedPrayer':
          l10n?.translate('settings.app_lock_overlay_completed_prayer') ??
          'I completed prayer',
      'holdBypass':
          l10n?.translate('settings.app_lock_overlay_hold_bypass') ??
          'Hold 3 seconds for emergency bypass',
      'keepHolding':
          l10n?.translate('settings.app_lock_overlay_keep_holding') ??
          'Keep holding...',
      'holdReady':
          l10n?.translate('settings.app_lock_overlay_hold_ready') ??
          'Hold complete. Confirm to unlock for 10 seconds.',
      'confirmBypass':
          l10n?.translate('settings.app_lock_overlay_confirm_bypass') ??
          'Confirm emergency bypass',
      'cancel': l10n?.translate('common.cancel') ?? 'Cancel',
    };
  }

  /// The hadith the lock screen rotates through.
  static Future<AppLockOverlayQuotes> quotes(
    AppLockHadithQuotesService service, {
    required bool useArabic,
  }) async {
    final quotes = await service.getAllQuotes(useArabic: useArabic);
    final messages = quotes
        .map((q) => q.message.trim())
        .where((m) => m.isNotEmpty)
        .toList();
    final references = quotes.map((q) => q.reference.trim()).toList();

    if (messages.isEmpty) {
      return const AppLockOverlayQuotes(
        initialMessage: _defaultMessage,
        initialReference: '',
        overlayMessages: [_defaultMessage],
        overlayReferences: [''],
      );
    }

    return AppLockOverlayQuotes(
      initialMessage: messages.first,
      initialReference: references.isNotEmpty ? references.first : '',
      overlayMessages: messages,
      overlayReferences: references,
    );
  }

  /// The current prayer window, or zeros when today's times are unknown.
  static AppLockWindowPayload window(PrayerTimesModel? today, DateTime now) {
    if (today == null) return const AppLockWindowPayload(0, 0);
    final window = AppLockPrayerWindow.fromPrayerTimes(today, now);
    if (window == null) return const AppLockWindowPayload(0, 0);
    return AppLockWindowPayload(
      window.windowStart.millisecondsSinceEpoch,
      window.nextPrayerStart.millisecondsSinceEpoch,
    );
  }

  /// The name of the prayer whose window is open now.
  static String prayerName(
    PrayerTimesModel? today,
    DateTime now, {
    required bool isArabic,
    AppLocalizations? l10n,
  }) {
    final fallback =
        l10n?.translate('settings.app_lock_prayer_name_fallback') ??
        'Prayer time';
    if (today == null) return fallback;

    final window = AppLockPrayerWindow.fromPrayerTimes(today, now);
    if (window == null) return fallback;

    if (window.windowStart == today.fajr) return isArabic ? 'الفجر' : 'Fajr';
    if (window.windowStart == today.dhuhr) return isArabic ? 'الظهر' : 'Dhuhr';
    if (window.windowStart == today.asr) return isArabic ? 'العصر' : 'Asr';
    if (window.windowStart == today.maghrib) {
      return isArabic ? 'المغرب' : 'Maghrib';
    }
    if (window.windowStart == today.isha) return isArabic ? 'العشاء' : 'Isha';
    return fallback;
  }
}

class AppLockOverlayQuotes {
  final String initialMessage;
  final String initialReference;
  final List<String> overlayMessages;
  final List<String> overlayReferences;

  const AppLockOverlayQuotes({
    required this.initialMessage,
    required this.initialReference,
    required this.overlayMessages,
    required this.overlayReferences,
  });
}

class AppLockWindowPayload {
  final int windowStartMs;
  final int nextPrayerStartMs;

  const AppLockWindowPayload(this.windowStartMs, this.nextPrayerStartMs);
}
