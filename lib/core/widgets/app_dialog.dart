import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// The `title` / `body` / `actions` dialog layout that forui shipped as a
/// first-class `FDialog(...)` constructor up to 0.23.
///
/// forui 0.26 removed it: `FDialog` now exposes only `builder` (and
/// `.adaptive`), and `FDialogStyle` lost its `contentStyle` — `titleTextStyle`
/// and `bodyTextStyle` moved to the top level. Rather than hand-roll the same
/// `Column` at the 15 call sites that used the old constructor, this rebuilds
/// the vertical layout once.
///
/// Spacing is copied from forui 0.23's `FDialogContentStyle` defaults so the
/// dialogs look unchanged after the upgrade:
///   content padding  `EdgeInsets.only(left: 16, right: 16, top: 18, bottom: 18)`
///   title/body padding `EdgeInsets.symmetric(horizontal: 8)`
///   title → body      9
///   content → actions 20
///   action → action   10
///
/// The one deliberate deviation: actions are stretched to full width. forui's
/// old vertical layout put them in a `mainAxisSize.min` Column, but its
/// `expandActions` default was `true` and its own docs diagram draws them
/// spanning the dialog, so stretching is what users actually saw. Left-aligned
/// intrinsic-width buttons would be a visible regression.
class AppDialog extends StatelessWidget {
  /// Shown first, in [FDialogStyle.titleTextStyle].
  final Widget? title;

  /// Shown under [title], in [FDialogStyle.bodyTextStyle]. Flexible, so long
  /// bodies scroll/shrink rather than overflow.
  final Widget? body;

  /// Ordered with the primary action FIRST — in this vertical layout the
  /// primary action sits on top, matching forui's original contract.
  final List<Widget> actions;

  const AppDialog({required this.actions, this.title, this.body, super.key});

  @override
  Widget build(BuildContext context) => FDialog(
    builder: (context, style) {
      final hasContent = title != null || body != null;
      return Padding(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 18,
          bottom: 18,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title case final title?)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Semantics(
                  container: true,
                  child: DefaultTextStyle.merge(
                    textAlign: TextAlign.start,
                    style: style.titleTextStyle,
                    child: title,
                  ),
                ),
              ),
            if (title != null && body != null) const SizedBox(height: 9),
            if (body case final body?)
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Semantics(
                    container: true,
                    child: DefaultTextStyle.merge(
                      textAlign: TextAlign.start,
                      style: style.bodyTextStyle,
                      child: body,
                    ),
                  ),
                ),
              ),
            if (hasContent && actions.isNotEmpty) const SizedBox(height: 20),
            if (actions.isNotEmpty)
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 10,
                children: actions,
              ),
          ],
        ),
      );
    },
  );
}
