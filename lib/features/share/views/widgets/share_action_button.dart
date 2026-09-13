import 'package:flutter/material.dart';
import 'package:wadhakir/core/constants/app_constants.dart';
import 'package:wadhakir/features/share/models/share_payload.dart';

/// The one way anything in this app offers "share this".
///
/// ## Why it is a widget and not a copied three-liner
///
/// Before R4, four of twenty-six features could share. Each one had its own
/// hand-rolled `Navigator.pushNamed(shareRoute, arguments: SharePayload(...))`
/// with its own icon, its own tooltip, and its own idea of how big the tap
/// target should be. Adding the other twenty-two that way would have meant
/// twenty-two chances to get the payload subtly wrong, and no single place to
/// change what sharing looks like afterwards.
///
/// The payload is built **lazily**, by [payloadBuilder], because most callers
/// sit inside a list or a page view where the item under the button changes as
/// the user scrolls. Capturing a payload at build time is how a share button
/// ends up sending the ayah you were looking at a moment ago.
class ShareActionButton extends StatelessWidget {
  const ShareActionButton({
    super.key,
    required this.payloadBuilder,
    this.tooltip,
    this.icon = Icons.ios_share_rounded,
    this.size = 20,
    this.color,
  });

  /// Called at tap time, not at build time. Returning null cancels the share —
  /// for a surface whose content can be momentarily absent.
  final SharePayload? Function() payloadBuilder;

  final String? tooltip;
  final IconData icon;
  final double size;
  final Color? color;

  void _share(BuildContext context) {
    final payload = payloadBuilder();
    if (payload == null) return;
    Navigator.of(
      context,
    ).pushNamed(AppConstants.shareRoute, arguments: payload);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton(
      icon: Icon(icon, size: size),
      color: color ?? theme.colorScheme.onSurfaceVariant,
      tooltip: tooltip ?? 'مشاركة',
      // A named route, so nothing here needs to import the share screen and the
      // whole feature stays reachable from anywhere without a dependency edge.
      onPressed: () => _share(context),
      // Matches the density of the icon rows these sit in across the app.
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    );
  }
}
