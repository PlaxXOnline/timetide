import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:timetide/src/core/models/event.dart';

void main() {
  final baseStart = DateTime(2024, 6, 1, 9, 0);
  final baseEnd = DateTime(2024, 6, 1, 10, 0);

  TideEvent makeEvent({
    String id = 'evt-1',
    String subject = 'Meeting',
    DateTime? startTime,
    DateTime? endTime,
    bool isAllDay = false,
    String? recurrenceRule,
  }) {
    return TideEvent(
      id: id,
      subject: subject,
      startTime: startTime ?? baseStart,
      endTime: endTime ?? baseEnd,
      isAllDay: isAllDay,
      recurrenceRule: recurrenceRule,
    );
  }

  group('TideEvent construction', () {
    test('required fields only — correct defaults', () {
      final event = makeEvent();
      expect(event.id, 'evt-1');
      expect(event.subject, 'Meeting');
      expect(event.isAllDay, isFalse);
      expect(event.color, isNull);
      expect(event.notes, isNull);
      expect(event.location, isNull);
      expect(event.recurrenceRule, isNull);
      expect(event.recurrenceExceptions, isNull);
      expect(event.resourceIds, isNull);
      expect(event.metadata, isNull);
    });

    test('all fields populated', () {
      final event = TideEvent(
        id: 'evt-2',
        subject: 'All-hands',
        startTime: baseStart,
        endTime: baseEnd,
        isAllDay: true,
        color: const Color(0xFFFF0000),
        notes: 'Bring laptop',
        location: 'Room A',
        recurrenceRule: 'FREQ=WEEKLY',
        recurrenceExceptions: [DateTime(2024, 6, 8)],
        resourceIds: ['res-1'],
        metadata: {'key': 'value'},
      );
      expect(event.isAllDay, isTrue);
      expect(event.color, const Color(0xFFFF0000));
      expect(event.notes, 'Bring laptop');
      expect(event.location, 'Room A');
      expect(event.recurrenceRule, 'FREQ=WEEKLY');
      expect(event.recurrenceExceptions, [DateTime(2024, 6, 8)]);
      expect(event.resourceIds, ['res-1']);
      expect(event.metadata, {'key': 'value'});
    });
  });

  group('TideEvent computed properties', () {
    test('duration returns correct value', () {
      final event = makeEvent(
        startTime: DateTime(2024, 6, 1, 9, 0),
        endTime: DateTime(2024, 6, 1, 10, 30),
      );
      expect(event.duration, const Duration(hours: 1, minutes: 30));
    });

    test('isRecurring is true when recurrenceRule is set', () {
      final event = makeEvent(recurrenceRule: 'FREQ=DAILY');
      expect(event.isRecurring, isTrue);
    });

    test('isRecurring is false when recurrenceRule is null', () {
      final event = makeEvent();
      expect(event.isRecurring, isFalse);
    });

    test('isMultiDay is true when event spans midnight', () {
      final event = makeEvent(
        startTime: DateTime(2024, 6, 1, 23, 0),
        endTime: DateTime(2024, 6, 2, 1, 0),
      );
      expect(event.isMultiDay, isTrue);
    });

    test('isMultiDay is false for same-day event', () {
      final event = makeEvent(
        startTime: DateTime(2024, 6, 1, 9, 0),
        endTime: DateTime(2024, 6, 1, 17, 0),
      );
      expect(event.isMultiDay, isFalse);
    });

    test('isMultiDay is false when isAllDay is true', () {
      final event = makeEvent(
        isAllDay: true,
        startTime: DateTime(2024, 6, 1),
        endTime: DateTime(2024, 6, 3),
      );
      expect(event.isMultiDay, isFalse);
    });
  });

  group('TideEvent copyWith', () {
    test('returns new instance with changed field', () {
      final original = makeEvent();
      final copy = original.copyWith(subject: 'Updated');
      expect(copy.subject, 'Updated');
      expect(copy.id, original.id);
    });

    test('copyWith with no changes returns equal instance', () {
      final original = makeEvent();
      final copy = original.copyWith();
      expect(copy, equals(original));
    });
  });

  group('TideEvent equality', () {
    test('same id — equal', () {
      final a = makeEvent(id: 'x');
      final b = makeEvent(id: 'x');
      expect(a, equals(b));
    });

    test('different id — not equal', () {
      final a = makeEvent(id: 'x');
      final b = makeEvent(id: 'y');
      expect(a, isNot(equals(b)));
    });

    test('same id but different subject — still equal', () {
      final a = TideEvent(id: 'x', subject: 'A', startTime: baseStart, endTime: baseEnd);
      final b = TideEvent(id: 'x', subject: 'B', startTime: baseStart, endTime: baseEnd);
      expect(a, equals(b));
    });

    test('hashCode is same for same id', () {
      final a = makeEvent(id: 'x');
      final b = makeEvent(id: 'x');
      expect(a.hashCode, b.hashCode);
    });
  });
}
