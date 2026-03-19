import 'package:flutter_test/flutter_test.dart';
import 'package:timetide/src/core/models/time_region.dart';

void main() {
  group('TideTimeRegion', () {
    final start = DateTime(2024, 1, 15, 9, 0);
    final end = DateTime(2024, 1, 15, 17, 0);

    test('construction with required fields', () {
      final region = TideTimeRegion(
        id: 'r1',
        startTime: DateTime(2024, 1, 15, 9, 0),
        endTime: DateTime(2024, 1, 15, 17, 0),
      );
      expect(region.id, 'r1');
      expect(region.text, isNull);
      expect(region.color, isNull);
      expect(region.recurrenceRule, isNull);
      expect(region.recurrenceExceptions, isNull);
      expect(region.resourceIds, isNull);
      expect(region.metadata, isNull);
    });

    test('default type is TimeRegionType.nonWorking', () {
      final region = TideTimeRegion(
        id: 'r1',
        startTime: DateTime(2024, 1, 15, 9, 0),
        endTime: DateTime(2024, 1, 15, 17, 0),
      );
      expect(region.type, TimeRegionType.nonWorking);
    });

    test('default enableInteraction is false', () {
      final region = TideTimeRegion(
        id: 'r1',
        startTime: DateTime(2024, 1, 15, 9, 0),
        endTime: DateTime(2024, 1, 15, 17, 0),
      );
      expect(region.enableInteraction, isFalse);
    });

    test('copyWith produces updated copy', () {
      final region = TideTimeRegion(
        id: 'r1',
        startTime: start,
        endTime: end,
        text: 'Lunch',
        type: TimeRegionType.blocked,
        enableInteraction: false,
      );

      final copy = region.copyWith(text: 'Updated', enableInteraction: true);
      expect(copy.id, 'r1');
      expect(copy.text, 'Updated');
      expect(copy.enableInteraction, isTrue);
      expect(copy.type, TimeRegionType.blocked);
      expect(copy.startTime, start);
    });

    test('equality is based on id', () {
      final r1a = TideTimeRegion(
        id: 'r1',
        startTime: start,
        endTime: end,
        text: 'A',
      );
      final r1b = TideTimeRegion(
        id: 'r1',
        startTime: start,
        endTime: end,
        text: 'B',
      );
      final r2 = TideTimeRegion(id: 'r2', startTime: start, endTime: end);

      expect(r1a, equals(r1b));
      expect(r1a.hashCode, equals(r1b.hashCode));
      expect(r1a, isNot(equals(r2)));
    });

    test('TimeRegionType has all 5 values', () {
      expect(TimeRegionType.values.length, 5);
      expect(TimeRegionType.values, containsAll([
        TimeRegionType.working,
        TimeRegionType.nonWorking,
        TimeRegionType.blocked,
        TimeRegionType.highlight,
        TimeRegionType.custom,
      ]));
    });
  });
}
