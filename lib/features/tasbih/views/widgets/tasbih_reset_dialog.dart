import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:wadhakir/core/design/design_tokens.dart';
import 'package:wadhakir/core/widgets/app_dialog.dart';

import '../tasbih_strings.dart';

/// Asks before anything is zeroed. Both resets go through here — the
/// counter's and the all-time total's — because the old screen had neither
/// and one stray tap on its trash icon wiped a lifetime of counting.
///
/// Resolves to true only on «تصفير».
Future<bool> confirmTasbihReset(
  BuildContext context, {
  required String title,
  required String body,
}) async {
  final confirmed = await showFDialog<bool>(
    context: context,
    builder: (ctx, style, animation) {
      final cs = Theme.of(ctx).colorScheme;
      final accent = AppAccent.of(ctx);
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      return AppDialog(
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: isDark ? 0.22 : 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.restart_alt_rounded, color: accent, size: 24),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(child: Text(title)),
          ],
        ),
        body: Text(body),
        actions: [
          FButton(
            variant: FButtonVariant.destructive,
            onPress: () => Navigator.of(ctx).pop(true),
            child: Text(TasbihStrings.tr(ctx, 'tasbih.reset_confirm')),
          ),
          FButton(
            variant: FButtonVariant.outline,
            onPress: () => Navigator.of(ctx).pop(false),
            child: Text(TasbihStrings.tr(ctx, 'tasbih.cancel')),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}
