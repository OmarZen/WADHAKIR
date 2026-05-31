import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wadhakir/data/repositories/hadith_nawawi_repository_impl.dart';
import 'package:wadhakir/features/hadith_nawawi/cubit/hadith_nawawi_state.dart';

class HadithNawawiCubit extends Cubit<HadithNawawiState> {
  final HadithNawawiRepository _repository;

  HadithNawawiCubit(this._repository) : super(const HadithNawawiLoading());

  Future<void> load() async {
    emit(const HadithNawawiLoading());
    try {
      final hadiths = await _repository.getHadiths();
      emit(HadithNawawiLoaded(hadiths));
    } catch (e, st) {
      log('🟥 HadithNawawiCubit.load: $e\n$st');
      emit(HadithNawawiError(e.toString()));
    }
  }
}
