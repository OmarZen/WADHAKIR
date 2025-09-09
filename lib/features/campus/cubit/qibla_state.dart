import 'package:equatable/equatable.dart';
import 'package:wadhakir/data/models/qibla_model.dart';

abstract class QiblaState extends Equatable {
  const QiblaState();

  @override
  List<Object?> get props => [];
}

class QiblaInitial extends QiblaState {
  const QiblaInitial();
}

class QiblaLoading extends QiblaState {
  const QiblaLoading();
}

class QiblaLoaded extends QiblaState {
  final QiblaModel qiblaModel;

  const QiblaLoaded(this.qiblaModel);

  @override
  List<Object?> get props => [qiblaModel];
}

class QiblaError extends QiblaState {
  final String message;

  const QiblaError(this.message);

  @override
  List<Object?> get props => [message];
}
