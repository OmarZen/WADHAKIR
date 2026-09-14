import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wadhakir/core/constants/app_constants.dart';
import 'package:wadhakir/data/models/app_settings_model.dart';
import 'package:wadhakir/data/repositories/app_settings_repository_impl.dart';
import 'package:wadhakir/features/settings/view/widgets/text_size_selector.dart';

void main() {
  group('text scale persistence', () {
    test('defaults to 1.0 when never set', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = AppSettingsRepositoryImpl(
        await SharedPreferences.getInstance(),
      );
      expect((await repo.getSettings()).textScale, 1.0);
    });

    test('round-trips a chosen scale', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = AppSettingsRepositoryImpl(
        await SharedPreferences.getInstance(),
      );
      await repo.setTextScale(1.25);
      expect((await repo.getSettings()).textScale, 1.25);
    });

    test('clamps a written value that is out of bounds', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = AppSettingsRepositoryImpl(
        await SharedPreferences.getInstance(),
      );
      await repo.setTextScale(9.0);
      expect(
        (await repo.getSettings()).textScale,
        AppSettingsModel.maxTextScale,
      );
      await repo.setTextScale(0.1);
      expect(
        (await repo.getSettings()).textScale,
        AppSettingsModel.minTextScale,
      );
    });

    test('clamps a corrupt value already in storage', () async {
      // A prefs file hand-edited, or written by a future build with wider
      // bounds, must not be able to render the UI unusable.
      SharedPreferences.setMockInitialValues({AppConstants.textScaleKey: 42.0});
      final repo = AppSettingsRepositoryImpl(
        await SharedPreferences.getInstance(),
      );
      expect(
        (await repo.getSettings()).textScale,
        AppSettingsModel.maxTextScale,
      );
    });
  });

  group('TextSizeSelector steps', () {
    test('every step is inside the model clamp bounds', () {
      for (final s in TextSizeSelector.steps) {
        expect(s, greaterThanOrEqualTo(AppSettingsModel.minTextScale));
        expect(s, lessThanOrEqualTo(AppSettingsModel.maxTextScale));
      }
    });

    test('steps are strictly ascending and span the full range', () {
      final steps = TextSizeSelector.steps;
      for (var i = 1; i < steps.length; i++) {
        expect(steps[i], greaterThan(steps[i - 1]));
      }
      expect(steps.first, AppSettingsModel.minTextScale);
      expect(steps.last, AppSettingsModel.maxTextScale);
      // 1.0 (the design size) must be reachable.
      expect(steps.contains(1.0), isTrue);
    });
  });
}
