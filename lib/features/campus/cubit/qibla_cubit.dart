import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wadhakir/data/models/qibla_model.dart';
import 'package:wadhakir/features/campus/cubit/qibla_state.dart';
import 'package:wadhakir/domain/usecases/get_qibla_direction_usecase.dart';
import 'package:wadhakir/domain/usecases/request_qibla_permissions_usecase.dart';

class QiblaCubit extends Cubit<QiblaState> {
  final GetQiblaDirectionUseCase _getQiblaDirectionUseCase;
  final RequestQiblaPermissionsUseCase _requestQiblaPermissionsUseCase;
  StreamSubscription<QiblaModel>? _qiblaSubscription;
  bool _wasAlignedBefore = false;
  static const double _alignmentThreshold = 5.0; // degrees

  QiblaCubit(
    this._getQiblaDirectionUseCase,
    this._requestQiblaPermissionsUseCase,
  ) : super(const QiblaInitial());

  Future<void> requestPermissions() async {
    try {
      await _requestQiblaPermissionsUseCase();
    } catch (e) {
      emit(QiblaError(e.toString()));
    }
  }

  Future<void> getQiblaDirection() async {
    emit(const QiblaLoading());

    try {
      await requestPermissions();

      await _qiblaSubscription?.cancel();
      _qiblaSubscription = _getQiblaDirectionUseCase().listen(
        (qiblaModel) {
          // Calculate the difference between Qibla direction and compass direction
          double angleDifference =
              (qiblaModel.qiblaDirection - qiblaModel.compassDirection).abs();

          // Normalize the angle to be between 0 and 180
          if (angleDifference > 180) {
            angleDifference = 360 - angleDifference;
          }

          // Check if user is aligned with Qibla
          final bool isAligned = angleDifference <= _alignmentThreshold;

          // Trigger haptic feedback when transitioning to aligned state
          if (isAligned && !_wasAlignedBefore) {
            HapticFeedback.mediumImpact();
            // Additional light feedback for better UX
            Future.delayed(const Duration(milliseconds: 100), () {
              HapticFeedback.lightImpact();
            });
          }

          _wasAlignedBefore = isAligned;

          emit(QiblaLoaded(qiblaModel, isAligned: isAligned));
        },
        onError: (error) => emit(QiblaError(error.toString())),
      );
    } catch (e) {
      emit(QiblaError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _qiblaSubscription?.cancel();
    return super.close();
  }
}
