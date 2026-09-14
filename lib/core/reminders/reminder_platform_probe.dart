import 'dart:developer';
import 'dart:io';

import 'package:flutter/services.dart';

/// Live platform facts the health screen reads at the moment it renders.
///
/// Separate from the ledger on purpose. The ledger is history and can only ever
/// support an *inference*; these are certainties, and the verdict ladder ranks
/// them above everything the ledger can say. A certainty that was cached is not
/// a certainty — every one of these can be changed by the user in system
/// settings while the app sits in the background.
abstract interface class ReminderPlatformProbe {
  /// Which of [channelKeys] the OS is currently blocking, or null if none is.
  ///
  /// Returns *which*, not *whether*. There are two adhan channels — «الأذان»
  /// and «أذان الفجر» — and a button that opens the healthy one shows the user
  /// a channel with nothing wrong and changes nothing.
  Future<String?> blockedChannel(List<String> channelKeys);
}

class MethodChannelReminderPlatformProbe implements ReminderPlatformProbe {
  /// The channel the alarm bridge already owns.
  static const MethodChannel channel = MethodChannel(
    'com.bloom.wadhakir/prayer_alarms',
  );

  const MethodChannelReminderPlatformProbe();

  @override
  Future<String?> blockedChannel(List<String> channelKeys) async {
    if (!Platform.isAndroid) return null;
    try {
      return await channel.invokeMethod<String>('blockedChannel', channelKeys);
    } catch (e) {
      // Null, never "blocked". Accusing the OS of muting the adhan on the
      // strength of a failed probe would send the user to change a setting
      // that was never the problem — and that verdict sits high enough in the
      // ladder to hide whatever is actually wrong.
      log('🔕 blockedChannel probe failed: $e');
      return null;
    }
  }
}

/// Never finds anything blocked. iOS, Windows, and tests.
///
/// iOS has no per-channel notification settings to query — the user's controls
/// there are per-app, which `isNotificationAllowed` already covers.
class NullReminderPlatformProbe implements ReminderPlatformProbe {
  const NullReminderPlatformProbe();

  @override
  Future<String?> blockedChannel(List<String> channelKeys) async => null;
}
