import 'package:equatable/equatable.dart';

enum UnsplashStatus { initial, loading, success, failure }

class UnsplashPhoto {
  final String id;
  final String imageUrl;
  final String photographerName;
  final String description;
  final String photographerUsername;

  UnsplashPhoto({
    required this.id,
    required this.imageUrl,
    required this.photographerName,
    required this.description,
    required this.photographerUsername,
  });
}

class UnsplashState extends Equatable {
  final UnsplashStatus status;
  final List<UnsplashPhoto> photos;
  final String? errorMessage;
  final int currentPhotoIndex;

  const UnsplashState({
    this.status = UnsplashStatus.initial,
    this.photos = const [],
    this.errorMessage,
    this.currentPhotoIndex = 0,
  });

  UnsplashState copyWith({
    UnsplashStatus? status,
    List<UnsplashPhoto>? photos,
    String? errorMessage,
    int? currentPhotoIndex,
  }) {
    return UnsplashState(
      status: status ?? this.status,
      photos: photos ?? this.photos,
      errorMessage: errorMessage ?? this.errorMessage,
      currentPhotoIndex: currentPhotoIndex ?? this.currentPhotoIndex,
    );
  }

  @override
  List<Object?> get props => [status, photos, errorMessage, currentPhotoIndex];
}
