import 'dart:developer';
import 'dart:io';

import 'package:flutter/services.dart';

/// The Dart face of the probed OEM autostart deep-links — roadmap #16.
///
/// All the judgement lives in `OemAutostart.kt`, which probes each candidate
/// component against this device's `PackageManager` and refuses to name one it
/// cannot open. This side does two things: it asks, and it turns the vendor key
/// that comes back into Arabic.
///
/// **The Arabic is composed here and never in Kotlin.** Same rule the alarm wire
/// format follows — a second author of user-facing copy on the native side is
/// drift waiting to happen.
abstract interface class OemAutostartBridge {
  /// The vendor key of a screen that exists on this device, or null.
  ///
  /// Null is the normal answer on most hardware — a Pixel has no such screen —
  /// and it means *render no button*. An intent that resolves to nothing must
  /// never produce one.
  Future<String?> resolveKey();

  /// Opens it. False when the probe no longer finds anything, which can happen
  /// between the screen rendering and the user pressing.
  Future<bool> open();
}

class MethodChannelOemAutostart implements OemAutostartBridge {
  /// The channel the alarm bridge already owns.
  static const MethodChannel channel = MethodChannel(
    'com.bloom.wadhakir/prayer_alarms',
  );

  const MethodChannelOemAutostart();

  @override
  Future<String?> resolveKey() async {
    if (!Platform.isAndroid) return null;
    try {
      return await channel.invokeMethod<String>('oemAutostartKey');
    } catch (e) {
      // MissingPluginException on a build with no native side, and anything a
      // vendor's PackageManager decides to throw. Both mean "no button".
      log('🔧 OemAutostart.resolveKey failed: $e');
      return null;
    }
  }

  @override
  Future<bool> open() async {
    if (!Platform.isAndroid) return false;
    try {
      return await channel.invokeMethod<bool>('openOemAutostart') ?? false;
    } catch (e) {
      log('🔧 OemAutostart.open failed: $e');
      return false;
    }
  }
}

/// Never resolves anything. iOS, Windows, and tests that want the no-button
/// path.
class NullOemAutostartBridge implements OemAutostartBridge {
  const NullOemAutostartBridge();

  @override
  Future<String?> resolveKey() async => null;

  @override
  Future<bool> open() async => false;
}

/// What the button says, per vendor.
///
/// Each string names the screen the way the vendor's own UI names it, in
/// Arabic, because a user who is told to open "التشغيل التلقائي" and finds a
/// menu called something else assumes they are in the wrong place and stops.
///
/// The keys are the ones `OemAutostart.kt` returns. An unknown key — a vendor
/// added natively and not here — falls back to the generic label rather than
/// rendering a key, which is what `AppLocalizations.translate` would do with a
/// missing translation.
class OemAutostartLabels {
  OemAutostartLabels._();

  static const Map<String, String> _byVendor = {
    'xiaomi': 'فتح «التشغيل التلقائي» في الأمان',
    'huawei': 'فتح «بدء التشغيل» في مدير الهاتف',
    'oppo': 'فتح «التشغيل التلقائي» في مركز الأمان',
    'oneplus': 'فتح «التشغيل المتسلسل» في الأمان',
    'vivo': 'فتح «التشغيل في الخلفية» في الأمان',
    'transsion': 'فتح «التشغيل التلقائي» في PhoneMaster',
    'samsung': 'فتح إعدادات البطارية للتطبيق',
    'meizu': 'فتح «التشغيل في الخلفية» في الأمان',
    'asus': 'فتح «التشغيل التلقائي» في مدير الهاتف',
    'nokia': 'فتح استثناءات توفير الطاقة',
  };

  static const String _generic = 'فتح إعدادات الجهاز للسماح بالتشغيل';

  /// The localisation key for [vendorKey], for `AppLocalizations.translate`.
  static String keyFor(String vendorKey) => 'reminder_health.oem.$vendorKey';

  /// The Arabic to show when the translation is missing.
  static String fallbackFor(String vendorKey) =>
      _byVendor[vendorKey] ?? _generic;

  /// Vendor keys this build knows how to label. Exposed so a test can hold it
  /// against `OemAutostart.kt`'s candidate list.
  static Set<String> get known => _byVendor.keys.toSet();
}
