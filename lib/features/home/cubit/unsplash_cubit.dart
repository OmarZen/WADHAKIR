import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:wadhakir/features/home/cubit/unsplash_state.dart';

class UnsplashCubit extends Cubit<UnsplashState> {
  UnsplashCubit() : super(const UnsplashState());

  Timer? _autoRefreshTimer;
  int _currentImageIndex = 0;

  // Get API key from .env if available, otherwise use hardcoded value for development
  static String get apiKey {
    try {
      return dotenv.env['UNSPLASH_API_KEY'] ??
          'jIKtA08FzvtZa16RLX2AKG1YZRiSS9ZZgW2QvXtREkQ';
    } catch (e) {
      // Fallback in case of any dotenv issues
      return 'jIKtA08FzvtZa16RLX2AKG1YZRiSS9ZZgW2QvXtREkQ';
    }
  }

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
      final connectivityResult = await Connectivity().checkConnectivity();

      if (connectivityResult == ConnectivityResult.none) {
        await _loadLocalImages();
      } else {
        await _fetchFromUnsplash();
      }

      // Start auto-refreshing after loading images
      startAutoRefresh();
    } catch (error) {
      await _loadLocalImages();
      emit(state.copyWith(
          status: UnsplashStatus.failure, errorMessage: error.toString()));
    }
  }

  Future<void> _fetchFromUnsplash() async {
    try {
      final url = Uri.parse(
          'https://api.unsplash.com/search/photos/?client_id=$apiKey&query=Mosque&orientation=landscape&per_page=20');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List<dynamic>;

        if (results.isNotEmpty) {
          final photos =
              results.map((photo) => UnsplashPhoto.fromJson(photo)).toList();

          // Filter out any photos with empty URLs (defensive coding)
          final validPhotos = photos
              .where((photo) =>
                  photo.imageUrl.isNotEmpty &&
                  photo.imageUrl.startsWith('http'))
              .toList();

          if (validPhotos.isNotEmpty) {
            emit(state.copyWith(
                status: UnsplashStatus.success,
                photos: validPhotos,
                currentPhotoIndex: 0));
          } else {
            log('No valid photos found in Unsplash response, falling back to local images');
            await _loadLocalImages();
          }
        } else {
          log('Empty results from Unsplash API, falling back to local images');
          await _loadLocalImages();
        }
      } else {
        log('Failed to fetch from Unsplash: ${response.statusCode} - ${response.body}');
        await _loadLocalImages();
      }
    } catch (error) {
      log('Exception while fetching from Unsplash: $error');
      await _loadLocalImages();
      emit(state.copyWith(
          status: UnsplashStatus.failure, errorMessage: error.toString()));
    }
  }

  Future<void> _loadLocalImages() async {
    try {
      final localImages = [
        'assets/images/mosques/pexels-berefsanzeynep-17019716.jpg',
        'assets/images/mosques/pexels-tahayasiryoney-19838128.jpg',
        'assets/images/mosques/pexels-tonesofmoment-27050027.jpg',
        'assets/images/mosques/pexels-rsapmech-12036986.jpg',
        'assets/images/mosques/pexels-yasirgurbuz-12593672.jpg',
        'assets/images/mosques/pexels-tomfisk-3023502.jpg',
      ];

      final List<UnsplashPhoto> localPhotos = [];

      for (String path in localImages) {
        final fileName = path.split('/').last;
        final photographerName = fileName.split('-')[1].replaceAll('.jpg', '');

        localPhotos.add(UnsplashPhoto(
          id: 'local-${localImages.indexOf(path)}',
          imageUrl: path,
          photographerName: photographerName,
          description: 'Beautiful Mosque',
          photographerUsername: 'local',
        ));
      }

      emit(state.copyWith(
          status: UnsplashStatus.success,
          photos: localPhotos,
          currentPhotoIndex: 0));
    } catch (error) {
      emit(state.copyWith(
          status: UnsplashStatus.failure,
          errorMessage: 'Failed to load local images: ${error.toString()}'));
    }
  }

  UnsplashPhoto? getCurrentMosqueImage() {
    if (state.photos.isEmpty) return null;
    return state.photos[state.currentPhotoIndex];
  }
}
