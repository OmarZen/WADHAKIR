import 'package:equatable/equatable.dart';
import 'package:wadhakir/data/models/hadith_nawawi_model.dart';

abstract class HadithNawawiState extends Equatable {
  const HadithNawawiState();

  @override
  List<Object?> get props => [];
}

class HadithNawawiLoading extends HadithNawawiState {
  const HadithNawawiLoading();
}

class HadithNawawiLoaded extends HadithNawawiState {
  final List<HadithNawawi> hadiths;

  const HadithNawawiLoaded(this.hadiths);

  @override
  List<Object?> get props => [hadiths.length];
}

class HadithNawawiError extends HadithNawawiState {
  final String message;

  const HadithNawawiError(this.message);

  @override
  List<Object?> get props => [message];
}
