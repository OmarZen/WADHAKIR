import 'package:equatable/equatable.dart';

class QiblaModel extends Equatable {
  final double latitude;
  final double longitude;
  final double qiblaDirection;
  final double compassDirection;

  const QiblaModel({
    required this.latitude,
    required this.longitude,
    required this.qiblaDirection,
    required this.compassDirection,
  });

  QiblaModel copyWith({
    double? latitude,
    double? longitude,
    double? qiblaDirection,
    double? compassDirection,
  }) {
    return QiblaModel(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      qiblaDirection: qiblaDirection ?? this.qiblaDirection,
      compassDirection: compassDirection ?? this.compassDirection,
    );
  }

  @override
  List<Object?> get props => [
    latitude,
    longitude,
    qiblaDirection,
    compassDirection,
  ];
}
