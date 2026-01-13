import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wadhakir/features/azkar/cubit/azkar_state.dart';
import 'package:wadhakir/data/models/azkar_category.dart';

import '../../../domain/repositories/azkar_repository.dart';

class AzkarCubit extends Cubit<AzkarState> {
  final AzkarRepository _azkarRepository;

  AzkarCubit({required AzkarRepository azkarRepository})
    : _azkarRepository = azkarRepository,
      super(AzkarInitial());

  Future<void> loadCategories() async {
    try {
      emit(AzkarLoading());
      final categories = await _azkarRepository.getAllCategories();
      emit(AzkarCategoriesLoaded(categories: categories));
    } catch (e) {
      emit(AzkarError(message: e.toString()));
    }
  }

  void selectCategory(AzkarCategory category) {
    emit(AzkarCategorySelected(category: category));
  }

  void selectItem(int index) {
    if (state is AzkarCategorySelected) {
      final currentState = state as AzkarCategorySelected;
      emit(
        AzkarCategorySelected(
          category: currentState.category,
          selectedItemIndex: index,
        ),
      );
    }
  }
}
