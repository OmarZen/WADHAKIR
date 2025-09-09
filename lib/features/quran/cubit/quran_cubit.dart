import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wadhakir/domain/usecases/get_surahs_usecase.dart';
import 'package:wadhakir/domain/usecases/get_surah_by_number_usecase.dart';
import 'package:wadhakir/domain/usecases/get_verses_by_surah_usecase.dart';
import 'package:wadhakir/features/quran/cubit/quran_state.dart';
import 'package:wadhakir/data/models/app_settings_model.dart';
import 'package:wadhakir/features/settings/cubit/settings_cubit.dart';
import 'package:wadhakir/features/settings/cubit/settings_state.dart';

import '../../../domain/usecases/get_place_of_revelation.dart';

class QuranCubit extends Cubit<QuranState> {
  final GetSurahsUseCase _getSurahsUseCase;
  final GetSurahByNumberUseCase _getSurahByNumberUseCase;
  final GetVersesBySurahUseCase _getVersesBySurahUseCase;
  final GetPlaceOfRevelationUseCase _getPlaceOfRevelationUseCase;
  final SettingsCubit _settingsCubit;

  QuranCubit({
    required GetSurahsUseCase getSurahsUseCase,
    required GetSurahByNumberUseCase getSurahByNumberUseCase,
    required GetVersesBySurahUseCase getVersesBySurahUseCase,
    required SettingsCubit settingsCubit,
    required GetPlaceOfRevelationUseCase getPlaceOfRevelationUseCase,
  }) : _getSurahsUseCase = getSurahsUseCase,
       _getSurahByNumberUseCase = getSurahByNumberUseCase,
       _getVersesBySurahUseCase = getVersesBySurahUseCase,
       _settingsCubit = settingsCubit,
       _getPlaceOfRevelationUseCase = getPlaceOfRevelationUseCase,
       super(const QuranInitial());

  Future<void> loadSurahs() async {
    emit(const QuranLoading());
    try {
      final surahs = await _getSurahsUseCase();
      emit(SurahsLoaded(surahs));
    } catch (e) {
      emit(QuranError(e.toString()));
    }
  }

  Future<void> loadSurahDetails(int surahNumber) async {
    emit(const QuranLoading());
    try {
      final surah = await _getSurahByNumberUseCase(surahNumber);
      final verses = await _getVersesBySurahUseCase(surahNumber);
      
      // Get settings from SettingsCubit
      final settingsState = _settingsCubit.state;
      bool showBasmala = false;
      
      if (settingsState is SettingsLoaded) {
        final AppSettingsModel settings = settingsState.settings;
        showBasmala = settings.showBasmala;
      }
      
      emit(SurahDetailsLoaded(
        surah: surah,
        verses: verses,
        basmala: "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
        showBasmala: showBasmala && surahNumber != 9, // Surah At-Tawbah (9) doesn't start with Basmala
      ));
    } catch (e) {
      emit(QuranError(e.toString()));
    }
  }

  Future<void> loadPlaceOfRevelation(int surahNumber) async {
    emit(const QuranLoading());
    try {
      final placeOfRevelation = await _getPlaceOfRevelationUseCase(surahNumber);
      emit(PlaceOfRevelationLoaded(placeOfRevelation));
    } catch (e) {
      emit(QuranError(e.toString()));
    }

  }
} 