import 'package:flutter/widgets.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';

/// The tasbih's copy, with the Arabic each key falls back to.
///
/// `AppLocalizations.translate` returns the KEY itself for a missing entry,
/// never null, so the usual `translate(k) ?? 'fallback'` only covers the case
/// where there is no localization at all. [tr] treats "came back as the key"
/// as missing too.
///
/// Every value here must equal `assets/lang/ar.json`; `tasbih_l10n_test.dart`
/// holds them together.
abstract final class TasbihStrings {
  static const Map<String, String> fallbacks = {
    'tasbih.title': 'السبحة',
    'tasbih.mode_beads': 'الحبات',
    'tasbih.mode_tap': 'النقر',
    'tasbih.mode_ring': 'الحلقة',
    'tasbih.mode_focus': 'التركيز',
    'tasbih.target_n': 'الهدف {n}',
    'tasbih.of_n': 'من {n}',
    'tasbih.count_of': '{count} من {n}',
    'tasbih.tap_button': 'اضغط للعدّ',
    'tasbih.hint_tap': 'اضغط على الزر للبدء',
    'tasbih.hint_anywhere': 'اضغط في أي مكان للعدّ',
    'tasbih.hint_screen_on': 'الشاشة تبقى مضاءة',
    'tasbih.hint_drag': 'اسحب الحبة للعدّ',
    'tasbih.drag_hint_rtl': 'اسحب الحبة لليسار للعدّ',
    'tasbih.drag_hint_ltr': 'اسحب الحبة لليمين للعدّ',
    'tasbih.round': 'الدورة',
    'tasbih.round_n': 'الدورة {n}',
    'tasbih.today_total': 'مجموع اليوم',
    'tasbih.round_done': 'اكتملت الدورة {n}',
    'tasbih.next_dhikr': 'الذكر التالي',
    'tasbih.prev_dhikr': 'الذكر السابق',
    'tasbih.settings': 'الإعدادات',
    'tasbih.settings_title': 'إعدادات السبحة',
    'tasbih.target_for': 'هدف «{dhikr}»',
    'tasbih.target_custom': 'مخصص',
    'tasbih.apply': 'تطبيق',
    'tasbih.vibrate': 'الاهتزاز مع كل تسبيحة',
    'tasbih.sound': 'صوت النقر',
    'tasbih.sound_hint': 'لا يُسمع والهاتف على الصامت',
    'tasbih.auto_advance': 'الانتقال للذكر التالي تلقائيًا',
    'tasbih.keep_screen_on': 'إبقاء الشاشة مضاءة',
    'tasbih.keep_screen_on_hint': 'مضاءة دائمًا في وضع التركيز',
    'tasbih.lifetime_total': 'المجموع منذ البداية',
    'tasbih.reset': 'إعادة ضبط',
    'tasbih.reset_title': 'تصفير العداد؟',
    'tasbih.reset_body':
        'سيُصفَّر العدد الحالي ({count}) ودورات «{dhikr}» لهذا اليوم. '
        'لا يمكن التراجع.',
    'tasbih.reset_confirm': 'تصفير',
    'tasbih.reset_total_action': 'تصفير المجموع',
    'tasbih.reset_total_title': 'تصفير المجموع الكلي؟',
    'tasbih.reset_total_body':
        'سيُصفَّر المجموع منذ البداية ({n}). لا يمكن التراجع.',
    'tasbih.cancel': 'إلغاء',
  };

  /// [key] in the active language, with each `{name}` in it replaced from
  /// [params].
  static String tr(
    BuildContext context,
    String key, [
    Map<String, Object> params = const {},
  ]) {
    final translated = AppLocalizations.of(context)?.translate(key);
    var text = translated == null || translated == key
        ? (fallbacks[key] ?? key)
        : translated;
    for (final entry in params.entries) {
      text = text.replaceAll('{${entry.key}}', '${entry.value}');
    }
    return text;
  }
}
