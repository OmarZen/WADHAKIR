import 'package:equatable/equatable.dart';
import '../../../data/models/hadith_model.dart';
import '../../../data/models/hadith_collection_metadata.dart';

/// Base state for Hadith Library
abstract class HadithLibraryState extends Equatable {
  const HadithLibraryState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class HadithLibraryInitial extends HadithLibraryState {
  const HadithLibraryInitial();
}

/// Loading state
class HadithLibraryLoading extends HadithLibraryState {
  const HadithLibraryLoading();
}

/// Collections loaded successfully
class HadithCollectionsLoaded extends HadithLibraryState {
  final List<HadithCollectionMetadata> collections;
  final List<HadithCollectionMetadata> popularCollections;

  const HadithCollectionsLoaded({
    required this.collections,
    required this.popularCollections,
  });

  @override
  List<Object?> get props => [collections, popularCollections];
}

/// Books list loaded for a collection
class HadithBooksLoaded extends HadithLibraryState {
  final String collectionId;
  final HadithCollectionMetadata collection;
  final Map<int, String> books;

  const HadithBooksLoaded({
    required this.collectionId,
    required this.collection,
    required this.books,
  });

  @override
  List<Object?> get props => [collectionId, collection, books];
}

/// Hadiths loaded for a book
class HadithsLoaded extends HadithLibraryState {
  final String collectionId;
  final int bookNumber;
  final String bookName;
  final List<HadithModel> hadiths;
  final List<String> activeLanguages;

  const HadithsLoaded({
    required this.collectionId,
    required this.bookNumber,
    required this.bookName,
    required this.hadiths,
    required this.activeLanguages,
  });

  @override
  List<Object?> get props => [
    collectionId,
    bookNumber,
    bookName,
    hadiths,
    activeLanguages,
  ];
}

/// Single hadith loaded for reading
class HadithReaderLoaded extends HadithLibraryState {
  final HadithModel hadith;
  final List<String> availableLanguages;
  final List<String> activeLanguages;
  final bool isBookmarked;

  const HadithReaderLoaded({
    required this.hadith,
    required this.availableLanguages,
    required this.activeLanguages,
    required this.isBookmarked,
  });

  @override
  List<Object?> get props => [
    hadith,
    availableLanguages,
    activeLanguages,
    isBookmarked,
  ];
}

/// Error state
class HadithLibraryError extends HadithLibraryState {
  final String message;

  const HadithLibraryError(this.message);

  @override
  List<Object?> get props => [message];
}
