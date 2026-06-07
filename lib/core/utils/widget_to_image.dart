import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

/// Capture helpers that turn a [RepaintBoundary] subtree into a PNG. Shared by
/// the share card and the Islamic-backgrounds wallpaper maker.
///
/// Wrap the target widget in `RepaintBoundary(key: key, child: ...)` and pass
/// that same [GlobalKey] here. [pixelRatio] 3.0 keeps the output sharp on
/// high-DPI receivers; raise it for full-resolution wallpapers.
Future<Uint8List?> captureBoundaryToPngBytes(
  GlobalKey key, {
  double pixelRatio = 3.0,
}) async {
  try {
    // Settle a couple of frames so a just-decoded background image is
    // composited into the boundary before we snapshot it. Callers should also
    // await the background's precache future first (see
    // ShareBackgroundLayer.precache) — that guarantees the bytes are decoded;
    // these frames guarantee they're painted.
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;
    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
    final ByteData? bytes = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    image.dispose();
    return bytes?.buffer.asUint8List();
  } catch (e, st) {
    debugPrint('captureBoundaryToPngBytes error: $e\n$st');
    return null;
  }
}

/// Capture the boundary and write it to a PNG in the temp directory. Returns
/// the file, or null on any failure.
Future<File?> captureBoundaryToPngFile(
  GlobalKey key, {
  double pixelRatio = 3.0,
  String prefix = 'wadhakir',
}) async {
  final bytes = await captureBoundaryToPngBytes(key, pixelRatio: pixelRatio);
  if (bytes == null) return null;
  try {
    final dir = await getTemporaryDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/$prefix-$ts.png');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  } catch (e, st) {
    debugPrint('captureBoundaryToPngFile error: $e\n$st');
    return null;
  }
}
