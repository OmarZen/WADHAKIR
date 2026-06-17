import 'package:flutter/material.dart';
import 'package:wadhakir/data/models/azkar_category.dart';
import 'package:wadhakir/data/repositories/azkar_repository_impl.dart';
import 'package:wadhakir/features/azkar/views/screens/azkar_category_details_screen.dart';

/// Resolves an [AzkarCategory] by its (possibly partial) title from adhkar.json
/// and shows [AzkarCategoryDetailsScreen].
///
/// Used for notification deep-links, where only the category title (a String)
/// is available as a route argument — [AzkarCategoryDetailsScreen] itself needs
/// the full category object.
class AzkarCategoryByTitleScreen extends StatelessWidget {
  final String title;

  const AzkarCategoryByTitleScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AzkarCategory>>(
      future: AzkarRepositoryImpl().getAllCategories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final categories = snapshot.data ?? const <AzkarCategory>[];
        final match = _find(categories);
        if (match == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(title)),
          );
        }
        return AzkarCategoryDetailsScreen(category: match);
      },
    );
  }

  AzkarCategory? _find(List<AzkarCategory> categories) {
    for (final c in categories) {
      if (c.title == title) return c;
    }
    // Fallback: tolerate slight title variations between data and the link.
    for (final c in categories) {
      if (c.title.contains(title) || title.contains(c.title)) return c;
    }
    return null;
  }
}
