import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wadhakir/features/home/cubit/unsplash_state.dart';

class UnsplashCubit extends Cubit<UnsplashState> {
  UnsplashCubit() : super(const UnsplashState());

  Timer? _autoRefreshTimer;
  int _currentImageIndex = 0;

  static final List<String> _localImages = List.generate(
    11,
    (index) => 'assets/images/mosques/${index + 1}.jpg',
  );

  void startAutoRefresh({Duration duration = const Duration(seconds: 300)}) {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(duration, (_) {
      rotateToNextImage();
    });
  }

  void rotateToNextImage() {
    if (state.photos.isNotEmpty) {
      _currentImageIndex = (_currentImageIndex + 1) % state.photos.length;
      emit(state.copyWith(currentPhotoIndex: _currentImageIndex));
    }
  }

  void pauseAutoRefresh() {
    _autoRefreshTimer?.cancel();
  }

  void resumeAutoRefresh({Duration duration = const Duration(seconds: 300)}) {
    startAutoRefresh(duration: duration);
  }

  @override
  Future<void> close() {
    _autoRefreshTimer?.cancel();
    return super.close();
  }

  Future<void> fetchMosqueImages() async {
    emit(state.copyWith(status: UnsplashStatus.loading));

    try {
      await _loadLocalImages();
      startAutoRefresh();
    } catch (error) {
      emit(
        state.copyWith(
          status: UnsplashStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _loadLocalImages() async {
    try {
      final localPhotos = _localImages
          .asMap()
          .entries
          .map(
            (entry) => UnsplashPhoto(
              id: 'local-${entry.key + 1}',
              imageUrl: entry.value,
              photographerName: 'Wadhakir',
              description: 'Beautiful Mosque',
              photographerUsername: 'local',
            ),
          )
          .toList();

      emit(
        state.copyWith(
          status: UnsplashStatus.success,
          photos: localPhotos,
          currentPhotoIndex: 0,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: UnsplashStatus.failure,
          errorMessage: 'Failed to load local images: ${error.toString()}',
        ),
      );
    }
  }

  UnsplashPhoto? getCurrentMosqueImage() {
    if (state.photos.isEmpty) return null;
    return state.photos[state.currentPhotoIndex];
  }
}
