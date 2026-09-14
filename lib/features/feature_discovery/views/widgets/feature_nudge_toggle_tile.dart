import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wadhakir/core/constants/app_constants.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/features/feature_discovery/services/feature_discovery_service.dart';

/// Master on/off toggle for the feature-discovery nudges. Reads/writes the
/// [AppConstants.featureNudgeEnabledKey] preference directly (it isn't part of
/// any cubit) and cancels/reschedules accordingly.
class FeatureNudgeToggleTile extends StatefulWidget {
  const FeatureNudgeToggleTile({super.key});

  @override
  State<FeatureNudgeToggleTile> createState() => _FeatureNudgeToggleTileState();
}

class _FeatureNudgeToggleTileState extends State<FeatureNudgeToggleTile> {
  bool _enabled = true;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _enabled = prefs.getBool(AppConstants.featureNudgeEnabledKey) ?? true;
      _loaded = true;
    });
  }

  Future<void> _toggle(bool value) async {
    setState(() => _enabled = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.featureNudgeEnabledKey, value);
    if (value) {
      await FeatureDiscoveryService.instance.maybeScheduleNext(prefs);
    } else {
      await FeatureDiscoveryService.instance.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Material(transparency) guards against the "ListTile splash may be
    // invisible" warning, matching the floating-dhikr tile in settings.
    return Material(
      type: MaterialType.transparency,
      child: SwitchListTile(
        secondary: const Icon(Icons.lightbulb_outline),
        title: Text(
          l10n?.translate('feature_discovery.title') ?? 'اقتراحات الميزات',
        ),
        subtitle: Text(
          l10n?.translate('feature_discovery.toggle_subtitle') ??
              'تذكير لطيف بميزات التطبيق التي لم تجرّبها بعد (مرة كل بضعة أيام)',
        ),
        value: _enabled,
        onChanged: _loaded ? _toggle : null,
      ),
    );
  }
}
