import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

/// Outcome of preparing the camera for AR Qibla mode.
enum QiblaArAvailability {
  ready,
  permissionDenied,
  permissionPermanentlyDenied,
  noCamera,
}

class QiblaArCameraResult {
  final QiblaArAvailability status;

  /// The chosen (back) camera; non-null only when [status] is `ready`.
  final CameraDescription? camera;

  const QiblaArCameraResult(this.status, [this.camera]);
}

/// Isolates all `camera` + permission concerns so the AR screen stays focused
/// on rendering. Requests the camera permission and resolves the back camera.
class QiblaArCameraService {
  const QiblaArCameraService._();

  static Future<QiblaArCameraResult> prepare() async {
    var status = await Permission.camera.status;
    if (status.isDenied || status.isRestricted || status.isLimited) {
      status = await Permission.camera.request();
    }

    if (status.isPermanentlyDenied) {
      return const QiblaArCameraResult(
        QiblaArAvailability.permissionPermanentlyDenied,
      );
    }
    if (!status.isGranted) {
      return const QiblaArCameraResult(QiblaArAvailability.permissionDenied);
    }

    List<CameraDescription> cameras;
    try {
      cameras = await availableCameras();
    } catch (_) {
      cameras = const [];
    }
    if (cameras.isEmpty) {
      return const QiblaArCameraResult(QiblaArAvailability.noCamera);
    }

    final back = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
    return QiblaArCameraResult(QiblaArAvailability.ready, back);
  }
}
