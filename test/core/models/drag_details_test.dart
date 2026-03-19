import 'package:flutter_test/flutter_test.dart';
import 'package:timetide/src/core/models/drag_details.dart';
import 'package:timetide/src/core/models/event.dart';

void main() {
  final baseEvent = TideEvent(
    id: 'e1',
    subject: 'Meeting',
    startTime: DateTime(2024, 1, 15, 10, 0),
    endTime: DateTime(2024, 1, 15, 11, 0),
  );

  final newStart = DateTime(2024, 1, 15, 14, 0);
  final newEnd = DateTime(2024, 1, 15, 15, 0);

  group('TideDragEndDetails', () {
    test('construction with required fields', () {
      final details = TideDragEndDetails(
        event: baseEvent,
        newStart: newStart,
        newEnd: newEnd,
      );
      expect(details.event, baseEvent);
      expect(details.newStart, newStart);
      expect(details.newEnd, newEnd);
      expect(details.newResourceId, isNull);
    });

    test('construction with optional resourceId', () {
      final details = TideDragEndDetails(
        event: baseEvent,
        newStart: newStart,
        newEnd: newEnd,
        newResourceId: 'res-A',
      );
      expect(details.newResourceId, 'res-A');
    });
  });

  group('TideResizeEndDetails', () {
    test('construction with required fields', () {
      final details = TideResizeEndDetails(
        event: baseEvent,
        newStart: newStart,
        newEnd: newEnd,
      );
      expect(details.event, baseEvent);
      expect(details.newStart, newStart);
      expect(details.newEnd, newEnd);
    });
  });

  group('TideDragUpdateDetails', () {
    test('construction with empty conflicts by default', () {
      final details = TideDragUpdateDetails(
        event: baseEvent,
        proposedStart: newStart,
      );
      expect(details.event, baseEvent);
      expect(details.proposedStart, newStart);
      expect(details.proposedResourceId, isNull);
      expect(details.conflicts, isEmpty);
    });

    test('construction with conflicts list', () {
      final conflict = TideEvent(
        id: 'e2',
        subject: 'Conflict',
        startTime: DateTime(2024, 1, 15, 14, 30),
        endTime: DateTime(2024, 1, 15, 15, 30),
      );
      final details = TideDragUpdateDetails(
        event: baseEvent,
        proposedStart: newStart,
        conflicts: [conflict],
      );
      expect(details.conflicts, hasLength(1));
      expect(details.conflicts.first, conflict);
    });
  });

  group('TideExternalDragData', () {
    test('construction with required fields', () {
      const data = TideExternalDragData(
        subject: 'Task',
        duration: Duration(hours: 1),
      );
      expect(data.subject, 'Task');
      expect(data.duration, const Duration(hours: 1));
      expect(data.color, isNull);
      expect(data.metadata, isNull);
    });
  });

  group('TideExternalDragEndDetails', () {
    test('construction with required fields', () {
      const data = TideExternalDragData(
        subject: 'Task',
        duration: Duration(hours: 1),
      );
      final details = TideExternalDragEndDetails(
        data: data,
        dropTime: newStart,
      );
      expect(details.data, data);
      expect(details.dropTime, newStart);
      expect(details.dropResourceId, isNull);
    });
  });

  group('Enums', () {
    test('TideDragStartBehavior has 3 values', () {
      expect(TideDragStartBehavior.values.length, 3);
      expect(TideDragStartBehavior.values, containsAll([
        TideDragStartBehavior.adaptive,
        TideDragStartBehavior.longPress,
        TideDragStartBehavior.immediate,
      ]));
    });

    test('TideResizeDirection has 3 values', () {
      expect(TideResizeDirection.values.length, 3);
      expect(TideResizeDirection.values, containsAll([
        TideResizeDirection.both,
        TideResizeDirection.startOnly,
        TideResizeDirection.endOnly,
      ]));
    });
  });
}
