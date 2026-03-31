import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timetide/src/core/controller.dart';
import 'package:timetide/src/core/models/event.dart';
import 'package:timetide/src/interaction/drag_drop/conflict_detector.dart';
import 'package:timetide/src/interaction/drag_drop/drag_handler.dart';
import 'package:timetide/src/interaction/drag_drop/snap_engine.dart';
import 'package:timetide/src/interaction/drag_drop/time_axis.dart';

void main() {
  // ─── TideSnapEngine ────────────────────────────────────

  group('TideSnapEngine', () {
    group('snapToGrid', () {
      test('snaps to nearest 15-minute boundary (round down)', () {
        final proposed = DateTime(2024, 1, 1, 9, 7);
        final snapped = TideSnapEngine.snapToGrid(
          proposed,
          const Duration(minutes: 15),
        );
        expect(snapped, DateTime(2024, 1, 1, 9, 0));
      });

      test('snaps to nearest 15-minute boundary (round up)', () {
        final proposed = DateTime(2024, 1, 1, 9, 8);
        final snapped = TideSnapEngine.snapToGrid(
          proposed,
          const Duration(minutes: 15),
        );
        expect(snapped, DateTime(2024, 1, 1, 9, 15));
      });

      test('already on grid returns same time', () {
        final proposed = DateTime(2024, 1, 1, 9, 30);
        final snapped = TideSnapEngine.snapToGrid(
          proposed,
          const Duration(minutes: 15),
        );
        expect(snapped, DateTime(2024, 1, 1, 9, 30));
      });

      test('null interval returns proposed unchanged', () {
        final proposed = DateTime(2024, 1, 1, 9, 22);
        final snapped = TideSnapEngine.snapToGrid(proposed, null);
        expect(snapped, proposed);
      });

      test('zero-duration interval returns proposed unchanged', () {
        final proposed = DateTime(2024, 1, 1, 9, 22);
        final snapped = TideSnapEngine.snapToGrid(
          proposed,
          Duration.zero,
        );
        expect(snapped, proposed);
      });

      test('snaps to nearest 30-minute boundary', () {
        final proposed = DateTime(2024, 1, 1, 9, 20);
        final snapped = TideSnapEngine.snapToGrid(
          proposed,
          const Duration(minutes: 30),
        );
        expect(snapped, DateTime(2024, 1, 1, 9, 30));
      });

      test('snaps to nearest 5-minute boundary', () {
        final proposed = DateTime(2024, 1, 1, 14, 32);
        final snapped = TideSnapEngine.snapToGrid(
          proposed,
          const Duration(minutes: 5),
        );
        expect(snapped, DateTime(2024, 1, 1, 14, 30));
      });

      test('snaps to nearest hour', () {
        final proposed = DateTime(2024, 1, 1, 14, 40);
        final snapped = TideSnapEngine.snapToGrid(
          proposed,
          const Duration(hours: 1),
        );
        expect(snapped, DateTime(2024, 1, 1, 15, 0));
      });

      test('preserves UTC flag', () {
        final proposed = DateTime.utc(2024, 1, 1, 9, 7);
        final snapped = TideSnapEngine.snapToGrid(
          proposed,
          const Duration(minutes: 15),
        );
        expect(snapped.isUtc, isTrue);
        expect(snapped, DateTime.utc(2024, 1, 1, 9, 0));
      });
    });

    group('snapDuration', () {
      test('snaps duration down to nearest interval', () {
        const proposed = Duration(minutes: 22);
        final snapped = TideSnapEngine.snapDuration(
          proposed,
          const Duration(minutes: 15),
        );
        expect(snapped, const Duration(minutes: 15));
      });

      test('snaps duration up to nearest interval', () {
        const proposed = Duration(minutes: 38);
        final snapped = TideSnapEngine.snapDuration(
          proposed,
          const Duration(minutes: 15),
        );
        expect(snapped, const Duration(minutes: 45));
      });

      test('ensures minimum of one interval', () {
        const proposed = Duration(minutes: 3);
        final snapped = TideSnapEngine.snapDuration(
          proposed,
          const Duration(minutes: 15),
        );
        expect(snapped, const Duration(minutes: 15));
      });

      test('null interval returns proposed unchanged', () {
        const proposed = Duration(minutes: 22);
        final snapped = TideSnapEngine.snapDuration(proposed, null);
        expect(snapped, proposed);
      });

      test('zero interval returns proposed unchanged', () {
        const proposed = Duration(minutes: 22);
        final snapped = TideSnapEngine.snapDuration(
          proposed,
          Duration.zero,
        );
        expect(snapped, proposed);
      });
    });
  });

  // ─── TideConflictDetector ──────────────────────────────

  group('TideConflictDetector', () {
    final baseEvent = TideEvent(
      id: 'dragged',
      subject: 'Dragged Event',
      startTime: DateTime(2024, 1, 1, 10, 0),
      endTime: DateTime(2024, 1, 1, 11, 0),
    );

    test('detects overlap with an existing event', () {
      final existing = TideEvent(
        id: 'existing',
        subject: 'Existing',
        startTime: DateTime(2024, 1, 1, 10, 30),
        endTime: DateTime(2024, 1, 1, 11, 30),
      );

      final conflicts = TideConflictDetector.detectConflicts(
        draggedEvent: baseEvent,
        proposedStart: DateTime(2024, 1, 1, 10, 0),
        proposedEnd: DateTime(2024, 1, 1, 11, 0),
        existingEvents: [existing],
      );

      expect(conflicts, hasLength(1));
      expect(conflicts.first.eventB.id, 'existing');
      expect(conflicts.first.overlapStart, DateTime(2024, 1, 1, 10, 30));
      expect(conflicts.first.overlapEnd, DateTime(2024, 1, 1, 11, 0));
    });

    test('returns empty list when no overlap', () {
      final existing = TideEvent(
        id: 'existing',
        subject: 'Existing',
        startTime: DateTime(2024, 1, 1, 12, 0),
        endTime: DateTime(2024, 1, 1, 13, 0),
      );

      final conflicts = TideConflictDetector.detectConflicts(
        draggedEvent: baseEvent,
        proposedStart: DateTime(2024, 1, 1, 10, 0),
        proposedEnd: DateTime(2024, 1, 1, 11, 0),
        existingEvents: [existing],
      );

      expect(conflicts, isEmpty);
    });

    test('excludes the dragged event itself', () {
      final conflicts = TideConflictDetector.detectConflicts(
        draggedEvent: baseEvent,
        proposedStart: DateTime(2024, 1, 1, 10, 0),
        proposedEnd: DateTime(2024, 1, 1, 11, 0),
        existingEvents: [baseEvent],
      );

      expect(conflicts, isEmpty);
    });

    test('adjacent events do not conflict', () {
      final adjacent = TideEvent(
        id: 'adjacent',
        subject: 'Adjacent',
        startTime: DateTime(2024, 1, 1, 11, 0),
        endTime: DateTime(2024, 1, 1, 12, 0),
      );

      final conflicts = TideConflictDetector.detectConflicts(
        draggedEvent: baseEvent,
        proposedStart: DateTime(2024, 1, 1, 10, 0),
        proposedEnd: DateTime(2024, 1, 1, 11, 0),
        existingEvents: [adjacent],
      );

      expect(conflicts, isEmpty);
    });

    test('detects multiple conflicts', () {
      final e1 = TideEvent(
        id: 'e1',
        subject: 'Event 1',
        startTime: DateTime(2024, 1, 1, 10, 15),
        endTime: DateTime(2024, 1, 1, 10, 45),
      );
      final e2 = TideEvent(
        id: 'e2',
        subject: 'Event 2',
        startTime: DateTime(2024, 1, 1, 10, 30),
        endTime: DateTime(2024, 1, 1, 11, 30),
      );

      final conflicts = TideConflictDetector.detectConflicts(
        draggedEvent: baseEvent,
        proposedStart: DateTime(2024, 1, 1, 10, 0),
        proposedEnd: DateTime(2024, 1, 1, 11, 0),
        existingEvents: [e1, e2],
      );

      expect(conflicts, hasLength(2));
    });

    test('filters by resource when proposedResourceId is given', () {
      final sameResource = TideEvent(
        id: 'same',
        subject: 'Same Resource',
        startTime: DateTime(2024, 1, 1, 10, 30),
        endTime: DateTime(2024, 1, 1, 11, 30),
        resourceIds: ['room-a'],
      );
      final differentResource = TideEvent(
        id: 'different',
        subject: 'Different Resource',
        startTime: DateTime(2024, 1, 1, 10, 30),
        endTime: DateTime(2024, 1, 1, 11, 30),
        resourceIds: ['room-b'],
      );

      final conflicts = TideConflictDetector.detectConflicts(
        draggedEvent: baseEvent,
        proposedStart: DateTime(2024, 1, 1, 10, 0),
        proposedEnd: DateTime(2024, 1, 1, 11, 0),
        existingEvents: [sameResource, differentResource],
        proposedResourceId: 'room-a',
      );

      expect(conflicts, hasLength(1));
      expect(conflicts.first.eventB.id, 'same');
    });

    test('complete containment is detected as a conflict', () {
      final contained = TideEvent(
        id: 'contained',
        subject: 'Contained',
        startTime: DateTime(2024, 1, 1, 10, 15),
        endTime: DateTime(2024, 1, 1, 10, 45),
      );

      final conflicts = TideConflictDetector.detectConflicts(
        draggedEvent: baseEvent,
        proposedStart: DateTime(2024, 1, 1, 10, 0),
        proposedEnd: DateTime(2024, 1, 1, 11, 0),
        existingEvents: [contained],
      );

      expect(conflicts, hasLength(1));
      expect(conflicts.first.overlapStart, DateTime(2024, 1, 1, 10, 15));
      expect(conflicts.first.overlapEnd, DateTime(2024, 1, 1, 10, 45));
    });
  });

  // ─── TideDragHandler Widget ────────────────────────────

  group('TideDragHandler', () {
    testWidgets('creates widget with Semantics', (tester) async {
      final event = TideEvent(
        id: '1',
        subject: 'Test Event',
        startTime: DateTime(2024, 1, 1, 10, 0),
        endTime: DateTime(2024, 1, 1, 11, 0),
      );
      final controller = TideController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideDragHandler(
            event: event,
            controller: controller,
            child: const SizedBox(width: 100, height: 60),
          ),
        ),
      );

      expect(find.byType(TideDragHandler), findsOneWidget);
      expect(find.byType(Semantics), findsWidgets);
    });

    testWidgets('renders child when disabled', (tester) async {
      final event = TideEvent(
        id: '1',
        subject: 'Test Event',
        startTime: DateTime(2024, 1, 1, 10, 0),
        endTime: DateTime(2024, 1, 1, 11, 0),
      );
      final controller = TideController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideDragHandler(
            event: event,
            controller: controller,
            enabled: false,
            child: const Text('Event'),
          ),
        ),
      );

      expect(find.text('Event'), findsOneWidget);
    });

    testWidgets('accepts optional TideTimeAxis parameter', (tester) async {
      final event = TideEvent(
        id: '1',
        subject: 'Test Event',
        startTime: DateTime(2024, 1, 1, 10, 0),
        endTime: DateTime(2024, 1, 1, 11, 0),
      );
      final controller = TideController();
      addTearDown(controller.dispose);

      final axis = TideTimeAxis.vertical(
        date: DateTime(2024, 1, 1),
        startHour: 0,
        hourHeight: 60,
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideDragHandler(
            event: event,
            controller: controller,
            timeAxis: axis,
            child: const SizedBox(width: 100, height: 60),
          ),
        ),
      );

      expect(find.byType(TideDragHandler), findsOneWidget);
    });

    testWidgets('builds correctly without timeAxis (backward-compatible)', (tester) async {
      final event = TideEvent(
        id: '1',
        subject: 'Test Event',
        startTime: DateTime(2024, 1, 1, 10, 0),
        endTime: DateTime(2024, 1, 1, 11, 0),
      );
      final controller = TideController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideDragHandler(
            event: event,
            controller: controller,
            // No timeAxis — backward-compatible mode.
            child: const SizedBox(width: 100, height: 60),
          ),
        ),
      );

      // Widget builds without timeAxis; handler reports original times.
      // Uses either GestureDetector (desktop/pan) or RawGestureDetector
      // (touch/long-press) depending on test environment pixel ratio.
      expect(find.byType(TideDragHandler), findsOneWidget);
      final hasGesture = find.byType(GestureDetector).evaluate().isNotEmpty;
      final hasRawGesture = find.byType(RawGestureDetector).evaluate().isNotEmpty;
      expect(hasGesture || hasRawGesture, isTrue);
    });
  });
}
