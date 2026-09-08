import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wadhakir/data/models/wird/wird_enums.dart';
import 'package:wadhakir/data/models/wird/wird_plan_model.dart';
import 'package:wadhakir/features/wird/services/wird_notification_service.dart';

WirdPlanModel _plan({WirdIntention? intention, String? dedication}) =>
    WirdPlanModel.defaultSettings().copyWith(
      isActive: true,
      intention: intention,
      dedication: dedication,
    );

void main() {
  group('WirdPlanModel dedication', () {
    test('defaults to no intention and no dedication', () {
      final plan = WirdPlanModel.defaultSettings();
      expect(plan.intention, WirdIntention.none);
      expect(plan.dedication, isNull);
    });

    test('omits both keys from JSON when unset', () {
      final json = WirdPlanModel.defaultSettings().toJson();
      expect(json.containsKey('intention'), isFalse);
      expect(json.containsKey('dedication'), isFalse);
    });

    test('round-trips a dedication', () {
      final plan = _plan(
        intention: WirdIntention.custom,
        dedication: 'إلى روح والدي',
      );
      final restored = WirdPlanModel.fromJson(
        jsonDecode(jsonEncode(plan.toJson())) as Map<String, dynamic>,
      );
      expect(restored.intention, WirdIntention.custom);
      expect(restored.dedication, 'إلى روح والدي');
    });

    test('a plan stored before dedications existed still decodes', () {
      // No 'intention' / 'dedication' keys at all — no migration needed.
      final legacy = {
        'isActive': true,
        'goalMode': 0,
        'unit': 0,
        'amountPerDay': 4,
        'startPage': 1,
        'reminderTime': '20:00',
        'reminderEnabled': true,
        'completedDayIndices': <int>[],
      };
      final plan = WirdPlanModel.fromJson(legacy);
      expect(plan.intention, WirdIntention.none);
      expect(plan.dedication, isNull);
      expect(plan.amountPerDay, 4);
    });

    test('an out-of-range intention index clamps instead of throwing', () {
      final plan = WirdPlanModel.fromJson({
        'isActive': true,
        'goalMode': 0,
        'unit': 0,
        'amountPerDay': 4,
        'startPage': 1,
        'reminderTime': '20:00',
        'reminderEnabled': true,
        'completedDayIndices': <int>[],
        'intention': 999,
      });
      expect(plan.intention, WirdIntention.values.last);
    });

    test('copyWith can clear the dedication via the sentinel', () {
      final plan = _plan(
        intention: WirdIntention.custom,
        dedication: 'إلى والدتي',
      );
      expect(plan.copyWith().dedication, 'إلى والدتي');
      expect(plan.copyWith(dedication: null).dedication, isNull);
    });
  });

  group('WirdNotificationService.reminderBody', () {
    test('falls back to the generic body with no dedication', () {
      expect(
        WirdNotificationService.reminderBody(WirdPlanModel.defaultSettings()),
        'حان وقت وردك اليومي من القرآن الكريم',
      );
    });

    test('names the dedication when one is set', () {
      final body = WirdNotificationService.reminderBody(
        _plan(intention: WirdIntention.custom, dedication: 'والدك'),
      );
      expect(body, contains('إهداءً إلى'));
      expect(body, contains('والدك'));
      // Deliberately NOT a pace-guilt message.
      expect(body, isNot(contains('متأخر')));
    });

    test('ignores a whitespace-only dedication', () {
      expect(
        WirdNotificationService.reminderBody(
          _plan(intention: WirdIntention.custom, dedication: '   '),
        ),
        'حان وقت وردك اليومي من القرآن الكريم',
      );
    });

    test('ignores a dedication when the intention was cleared', () {
      expect(
        WirdNotificationService.reminderBody(
          _plan(intention: WirdIntention.none, dedication: 'والدك'),
        ),
        'حان وقت وردك اليومي من القرآن الكريم',
      );
    });
  });
}
