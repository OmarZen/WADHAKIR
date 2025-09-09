import 'package:equatable/equatable.dart';
import 'package:wadhakir/data/models/azkar_category.dart';

abstract class AzkarState extends Equatable {
  const AzkarState();

  @override
  List<Object?> get props => [];
}

class AzkarInitial extends AzkarState {}

class AzkarLoading extends AzkarState {}

class AzkarCategoriesLoaded extends AzkarState {
  final List<AzkarCategory> categories;

  const AzkarCategoriesLoaded({required this.categories});

  @override
  List<Object?> get props => [categories];
}

class AzkarCategorySelected extends AzkarState {
  final AzkarCategory category;
  final int selectedItemIndex;

  const AzkarCategorySelected({
    required this.category,
    this.selectedItemIndex = 0,
  });

  @override
  List<Object?> get props => [category, selectedItemIndex];
}

class AzkarError extends AzkarState {
  final String message;

  const AzkarError({required this.message});

  @override
  List<Object?> get props => [message];
}
