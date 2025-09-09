import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vector_math/vector_math.dart';
import 'package:wadhakir/data/models/qibla_model.dart';
import 'package:wadhakir/domain/repositories/qibla_repository.dart';

class QiblaRepositoryImpl implements QiblaRepository {
  // Coordinates of Kaaba in Mecca
  final double kaabaLatitude = 21.422487;
  final double kaabaLongitude = 39.826206;

  // Stream controllers
  final StreamController<QiblaModel> _qiblaStreamController =
      StreamController<QiblaModel>.broadcast();
  StreamSubscription<CompassEvent>? _compassSubscription;
  Position? _currentPosition;
  bool _isCompassAvailable = false;

  QiblaRepositoryImpl() {
    _checkCompassAvailability();
    _initLocation();
  }

  Future<void> _checkCompassAvailability() async {
    try {
      _isCompassAvailable = FlutterCompass.events != null;
      if (_isCompassAvailable) {
        _initCompass();
      } else {
        _qiblaStreamController.addError('Compass not available on this device');
      }
    } catch (e) {
      debugPrint('Error checking compass availability: $e');
      _isCompassAvailable = false;
      _qiblaStreamController.addError('Compass error: $e');
    }
  }

  @override
  Stream<QiblaModel> getQiblaDirection() {
    return _qiblaStreamController.stream;
  }

  @override
  Future<void> requestPermissions() async {
    try {
      await _checkLocationPermission();
      if (_currentPosition == null) {
        await _initLocation();
      }
    } catch (e) {
      _qiblaStreamController.addError('Permission error: $e');
      rethrow;
    }
  }

  Future<void> _initLocation() async {
    try {
      await _checkLocationPermission();
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _updateQiblaDirection(null);
    } catch (e) {
      // Handle location error
      debugPrint('Error getting location: $e');
      _qiblaStreamController.addError('Location error: $e');
    }
  }

  Future<bool> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled
      _qiblaStreamController.addError('Location services are disabled');
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, try again next time.
        _qiblaStreamController.addError('Location permissions denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are permanently denied, handle accordingly.
      _qiblaStreamController.addError(
          'Location permissions are permanently denied, please enable in app settings');
      return false;
    }

    return true;
  }

  void _initCompass() {
    if (!_isCompassAvailable || FlutterCompass.events == null) {
      // Device does not support compass
      _qiblaStreamController.addError('Compass not available on this device');
      return;
    }

    try {
      _compassSubscription = FlutterCompass.events!.listen(
        (CompassEvent event) {
          _updateQiblaDirection(event);
        },
        onError: (error) {
          debugPrint('Compass error: $error');
          _qiblaStreamController.addError('Compass error: $error');
        },
      );
    } catch (e) {
      debugPrint('Error initializing compass: $e');
      _qiblaStreamController.addError('Error initializing compass: $e');
    }
  }

  void _updateQiblaDirection(CompassEvent? compassEvent) {
    if (_currentPosition == null) return;

    try {
      // Calculate Qibla direction
      double qiblaDirection = _calculateQiblaDirection(
          _currentPosition!.latitude, _currentPosition!.longitude);

      // Add new Qibla model to stream
      _qiblaStreamController.add(QiblaModel(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        qiblaDirection: qiblaDirection,
        compassDirection: compassEvent?.heading ?? 0.0,
      ));
    } catch (e) {
      debugPrint('Error updating Qibla direction: $e');
    }
  }

  double _calculateQiblaDirection(double latitude, double longitude) {
    double latRad = radians(latitude);
    double longRad = radians(longitude);
    double kaabaLatRad = radians(kaabaLatitude);
    double kaabaLongRad = radians(kaabaLongitude);

    // Formula to calculate Qibla direction
    double y = math.sin(kaabaLongRad - longRad);
    double x = math.cos(latRad) * math.tan(kaabaLatRad) -
        math.sin(latRad) * math.cos(kaabaLongRad - longRad);

    double qiblaRad = math.atan2(y, x);
    // Convert to degrees and normalize
    double qiblaDegrees = degrees(qiblaRad);

    // Normalize to 0-360
    return (qiblaDegrees + 360) % 360;
  }

  void dispose() {
    _compassSubscription?.cancel();
    _qiblaStreamController.close();
  }
}
