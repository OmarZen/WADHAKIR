import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Where to apply the wallpaper.
enum WallpaperTarget { home, lock, both }

/// Sets a STATIC wallpaper natively via Android's WallpaperManager (a small
/// MethodChannel handled in MainActivity). Android only — iOS forbids apps
/// from setting the wallpaper, so [isSupported] is false there and callers
/// should hide the action.
class WallpaperService {
  const WallpaperService._();

  static const MethodChannel _channel = MethodChannel(
    'com.bloom.wadhakir/wallpaper',
  );

  static bool get isSupported => !kIsWeb && Platform.isAndroid;

  /// Sets [filePath] as the wallpaper for [target]. Returns true on success.
  static Future<bool> setFromFile(
    String filePath,
    WallpaperTarget target,
  ) async {
    if (!isSupported) return false;
    try {
      final ok = await _channel.invokeMethod<bool>('setFromFile', {
        'path': filePath,
        'target': target.name, // 'home' | 'lock' | 'both'
      });
      return ok ?? false;
    } catch (e) {
      debugPrint('WallpaperService.setFromFile error: $e');
      return false;
    }
  }
}
