import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/domain/usecases/get_books_list_usecase.dart';
import 'package:wadhakir/domain/usecases/get_hadith_book_usecase.dart';
import 'package:wadhakir/data/repositories/hadith_repository_impl.dart';
import 'package:wadhakir/data/repositories/bookmark_repository_impl.dart';
import 'package:wadhakir/features/hadith_library/cubit/hadith_library_cubit.dart';
import 'package:wadhakir/features/hadith_library/views/screens/hadith_library_screen.dart';

class HadithLibraryGridItem extends StatelessWidget {
  const HadithLibraryGridItem({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => _navigateToHadithLibrary(context),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  color: isDark
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.8)
                      : theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n?.translate('home.hadith_library') ?? 'مكتبة الأحاديث',
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToHadithLibrary(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) {
            final hadithRepo = HadithRepositoryImpl();
            final bookmarkRepo = BookmarkRepositoryImpl();

            return HadithLibraryCubit(
              getHadithBookUseCase: GetHadithBookUseCase(hadithRepo),
              getBooksListUseCase: GetBooksListUseCase(hadithRepo),
              bookmarkRepository: bookmarkRepo,
            )..loadCollections();
          },
          child: const HadithLibraryScreen(),
        ),
      ),
    );
  }
}
