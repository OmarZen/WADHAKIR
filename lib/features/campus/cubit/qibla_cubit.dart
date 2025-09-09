import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wadhakir/data/models/qibla_model.dart';
import 'package:wadhakir/features/campus/cubit/qibla_state.dart';
import 'package:wadhakir/domain/usecases/get_qibla_direction_usecase.dart';
import 'package:wadhakir/domain/usecases/request_qibla_permissions_usecase.dart';

class QiblaCubit extends Cubit<QiblaState> {
  final GetQiblaDirectionUseCase _getQiblaDirectionUseCase;
  final RequestQiblaPermissionsUseCase _requestQiblaPermissionsUseCase;
  StreamSubscription<QiblaModel>? _qiblaSubscription;

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
        (qiblaModel) => emit(QiblaLoaded(qiblaModel)),
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
