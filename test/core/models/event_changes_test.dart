import 'package:flutter_test/flutter_test.dart';
import 'package:timetide/src/core/models/event_changes.dart';
import 'package:timetide/src/core/models/event.dart';

void main() {
  final baseEvent = TideEvent(
    id: 'e1',
    subject: 'Original Subject',
    startTime: DateTime(2024, 1, 15, 10, 0),
    endTime: DateTime(2024, 1, 15, 11, 0),
    notes: 'Original notes',
    location: 'Room A',
  );

  group('TideEventChanges', () {
    test('construction with no fields — isEmpty is true', () {
      const changes = TideEventChanges();
      expect(changes.isEmpty, isTrue);
    });

    test('construction with some fields — isEmpty is false', () {
      const changes = TideEventChanges(subject: 'New Title');
      expect(changes.isEmpty, isFalse);
    });

    test('construction with only non-subject field — isEmpty is false', () {
      final changes = TideEventChanges(startTime: DateTime(2024, 2, 1));
      expect(changes.isEmpty, isFalse);
    });

    test('applyTo correctly applies subject change', () {
      const changes = TideEventChanges(subject: 'Updated Subject');
      final result = changes.applyTo(baseEvent);
      expect(result.subject, 'Updated Subject');
      expect(result.id, 'e1');
    });

    test('applyTo correctly applies multiple changes', () {
      final newStart = DateTime(2024, 1, 15, 14, 0);
      final newEnd = DateTime(2024, 1, 15, 15, 0);
      final changes = TideEventChanges(
        subject: 'Board Meeting',
        startTime: newStart,
        endTime: newEnd,
        location: 'Conference Room B',
      );
      final result = changes.applyTo(baseEvent);
      expect(result.subject, 'Board Meeting');
      expect(result.startTime, newStart);
      expect(result.endTime, newEnd);
      expect(result.location, 'Conference Room B');
    });

    test('applyTo preserves unchanged fields', () {
      const changes = TideEventChanges(subject: 'New Title');
      final result = changes.applyTo(baseEvent);
      expect(result.startTime, baseEvent.startTime);
      expect(result.endTime, baseEvent.endTime);
      expect(result.notes, baseEvent.notes);
      expect(result.location, baseEvent.location);
      expect(result.isAllDay, baseEvent.isAllDay);
    });

    test('applyTo with empty changes returns equivalent event (same id)', () {
      const changes = TideEventChanges();
      final result = changes.applyTo(baseEvent);
      // Equality is based on id
      expect(result, equals(baseEvent));
      expect(result.subject, baseEvent.subject);
      expect(result.startTime, baseEvent.startTime);
      expect(result.endTime, baseEvent.endTime);
    });
  });
}
