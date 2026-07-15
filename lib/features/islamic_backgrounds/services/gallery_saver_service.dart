import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';

/// Saves rendered PNGs to the device gallery via `gal` (uses MediaStore on
/// modern Android and the photo library on iOS). Groups saves under a
/// "Wadhakir" album.
class GallerySaverService {
  const GallerySaverService._();

  static const String _album = 'Wadhakir';

  static Future<bool> _ensureAccess() async {
    try {
      if (await Gal.hasAccess(toAlbum: true)) return true;
      return await Gal.requestAccess(toAlbum: true);
    } catch (e) {
      debugPrint('GallerySaverService.ensureAccess error: $e');
      return false;
    }
  }

  /// Save a PNG file (by path) to the gallery. Returns true on success.
  static Future<bool> saveFile(String path) async {
    if (!await _ensureAccess()) return false;
    try {
      await Gal.putImage(path, album: _album);
      return true;
    } on GalException catch (e) {
      debugPrint('GallerySaverService.saveFile GalException: ${e.type}');
      return false;
    } catch (e) {
      debugPrint('GallerySaverService.saveFile error: $e');
      return false;
    }
  }

  /// Save raw PNG bytes to the gallery. Returns true on success.
  static Future<bool> saveBytes(
    Uint8List bytes, {
    String name = 'wadhakir',
  }) async {
    if (!await _ensureAccess()) return false;
    try {
      await Gal.putImageBytes(bytes, album: _album, name: name);
      return true;
    } on GalException catch (e) {
      debugPrint('GallerySaverService.saveBytes GalException: ${e.type}');
      return false;
    } catch (e) {
      debugPrint('GallerySaverService.saveBytes error: $e');
      return false;
    }
  }
}
