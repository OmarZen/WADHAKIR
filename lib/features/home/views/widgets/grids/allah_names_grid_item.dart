import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:wadhakir/core/platform/platform_utils.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';

class AllahNamesGridItem extends StatelessWidget {
  const AllahNamesGridItem({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = PlatformUtils.isDesktop;

    final padding = isDesktop ? 16.0 : 12.0;
    final verticalPadding = isDesktop ? 12.0 : 10.0;
    final iconPadding = isDesktop ? 10.0 : 8.0;
    final iconSize = isDesktop ? 22.0 : 20.0;
    final spacing = isDesktop ? 12.0 : 10.0;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => _showAllahNamesSheet(context),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: padding, vertical: verticalPadding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(iconPadding),
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(8.0),
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                ),
                child: Icon(
                  Icons.collections_bookmark,
                  size: iconSize,
                  color: isDark
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.8)
                      : theme.colorScheme.primary,
                ),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: Text(
                  l10n?.translate('home.asmallah') ?? 'أسماء الله الحسنى',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: isDesktop ? 16 : null,
                  ),
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

  Future<void> _showAllahNamesSheet(BuildContext context) async {
    final theme = Theme.of(context);
    final data =
        await rootBundle.loadString('assets/json_data/Names_Of_Allah.json');
    final List<dynamic> list = json.decode(data) as List<dynamic>;
    final items = list
        .map((e) => (
              id: e['id'] as int,
              name: e['name'] as String,
              text: e['text'] as String,
            ))
        .toList(growable: false);

    if (!context.mounted) return;

    // ignore: use_build_context_synchronously
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final l10n = context.l10n;
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.menu_book_rounded,
                        color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      l10n?.translate('home.asmallah') ?? 'أسماء الله الحسنى',
                      style: theme.textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              _IslamicDivider(),
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: theme.colorScheme.surface,
                        border: Border.all(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.18),
                        ),
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            item.name,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme.primary,
                              fontFamily: 'ScheherazadeNew',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.text,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(height: 1.6),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class _IslamicDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
              child: Divider(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2))),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3)),
            ),
            child: Icon(Icons.star, size: 12, color: theme.colorScheme.primary),
          ),
          Expanded(
              child: Divider(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2))),
        ],
      ),
    );
  }
}
