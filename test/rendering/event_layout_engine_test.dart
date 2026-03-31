import 'package:flutter_test/flutter_test.dart';
import 'package:timetide/src/core/models/event.dart';
import 'package:timetide/src/rendering/event_layout_engine.dart';

void main() {
  // Shared helpers --------------------------------------------------------

  TideEvent makeEvent(
    String id, {
    required int startHour,
    required int endHour,
    int startMinute = 0,
    int endMinute = 0,
    bool isAllDay = false,
  }) {
    return TideEvent(
      id: id,
      subject: 'Event $id',
      startTime: DateTime(2026, 3, 19, startHour, startMinute),
      endTime: DateTime(2026, 3, 19, endHour, endMinute),
      isAllDay: isAllDay,
    );
  }

  const width = 400.0;
  const height = 960.0; // 24h × 40px
  const startHour = 0.0;
  const endHour = 24.0;

  // -- TideEventBounds ----------------------------------------------------

  group('TideEventBounds', () {
    test('equality and hashCode', () {
      const a = TideEventBounds(left: 0, top: 10, width: 100, height: 50);
      const b = TideEventBounds(left: 0, top: 10, width: 100, height: 50);
      const c = TideEventBounds(left: 1, top: 10, width: 100, height: 50);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('copyWith replaces fields', () {
      const original =
          TideEventBounds(left: 0, top: 10, width: 100, height: 50);
      final modified = original.copyWith(left: 5, height: 80);
      expect(modified.left, 5);
      expect(modified.top, 10);
      expect(modified.width, 100);
      expect(modified.height, 80);
    });

    test('toString contains field values', () {
      const bounds =
          TideEventBounds(left: 1.0, top: 2.0, width: 3.0, height: 4.0);
      expect(bounds.toString(), contains('1.0'));
      expect(bounds.toString(), contains('4.0'));
    });
  });

  // -- TideEventLayoutResult -----------------------------------------------

  group('TideEventLayoutResult', () {
    test('equality and hashCode', () {
      final event = makeEvent('a', startHour: 9, endHour: 10);
      const bounds =
          TideEventBounds(left: 0, top: 0, width: 100, height: 40);
      final a = TideEventLayoutResult(event: event, bounds: bounds);
      final b = TideEventLayoutResult(event: event, bounds: bounds);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  // -- All-day filtering --------------------------------------------------

  group('All-day filtering', () {
    test('all-day events are excluded from layout', () {
      final events = [
        makeEvent('allDay', startHour: 0, endHour: 0, isAllDay: true),
        makeEvent('timed', startHour: 9, endHour: 10),
      ];

      for (final strategy in TideOverlapStrategy.values) {
        final results = TideEventLayoutEngine.layout(
          events: events,
          strategy: strategy,
          startHour: startHour,
          endHour: endHour,
          availableWidth: width,
          availableHeight: height,
        );
        expect(results.length, 1, reason: 'strategy: $strategy');
        expect(results.first.event.id, 'timed');
      }
    });

    test('empty list returns empty results', () {
      final results = TideEventLayoutEngine.layout(
        events: [],
        strategy: TideOverlapStrategy.sideBySide,
        startHour: startHour,
        endHour: endHour,
        availableWidth: width,
        availableHeight: height,
      );
      expect(results, isEmpty);
    });

    test('only all-day events returns empty results', () {
      final events = [
        makeEvent('a', startHour: 0, endHour: 0, isAllDay: true),
      ];
      final results = TideEventLayoutEngine.layout(
        events: events,
        strategy: TideOverlapStrategy.sideBySide,
        startHour: startHour,
        endHour: endHour,
        availableWidth: width,
        availableHeight: height,
      );
      expect(results, isEmpty);
    });
  });

  // -- Side-by-side -------------------------------------------------------

  group('sideBySide', () {
    test('single event spans full width', () {
      final events = [makeEvent('a', startHour: 9, endHour: 10)];
      final results = TideEventLayoutEngine.layout(
        events: events,
        strategy: TideOverlapStrategy.sideBySide,
        startHour: startHour,
        endHour: endHour,
        availableWidth: width,
        availableHeight: height,
      );

      expect(results.length, 1);
      final b = results.first.bounds;
      expect(b.left, 0.0);
      expect(b.width, width);
      // 9/24 * 960 = 360
      expect(b.top, closeTo(360.0, 0.01));
      // 1h / 24h * 960 = 40
      expect(b.height, closeTo(40.0, 0.01));
    });

    test('two non-overlapping events each get full width', () {
      final events = [
        makeEvent('a', startHour: 9, endHour: 10),
        makeEvent('b', startHour: 11, endHour: 12),
      ];
      final results = TideEventLayoutEngine.layout(
        events: events,
        strategy: TideOverlapStrategy.sideBySide,
        startHour: startHour,
        endHour: endHour,
        availableWidth: width,
        availableHeight: height,
      );

      expect(results.length, 2);
      for (final r in results) {
        expect(r.bounds.width, width);
      }
    });

    test('two overlapping events split width equally', () {
      final events = [
        makeEvent('a', startHour: 9, endHour: 11),
        makeEvent('b', startHour: 10, endHour: 12),
      ];
      final results = TideEventLayoutEngine.layout(
        events: events,
        strategy: TideOverlapStrategy.sideBySide,
        startHour: startHour,
        endHour: endHour,
        availableWidth: width,
        availableHeight: height,
      );

      expect(results.length, 2);
      final a = results.firstWhere((r) => r.event.id == 'a').bounds;
      final b = results.firstWhere((r) => r.event.id == 'b').bounds;

      expect(a.width, closeTo(width / 2, 0.01));
      expect(b.width, closeTo(width / 2, 0.01));
      // One should be left-aligned, the other shifted.
      expect(a.left, closeTo(0.0, 0.01));
      expect(b.left, closeTo(width / 2, 0.01));
    });

    test('three mutually overlapping events get three columns', () {
      final events = [
        makeEvent('a', startHour: 9, endHour: 12),
        makeEvent('b', startHour: 10, endHour: 13),
        makeEvent('c', startHour: 11, endHour: 14),
      ];
      final results = TideEventLayoutEngine.layout(
        events: events,
        strategy: TideOverlapStrategy.sideBySide,
        startHour: startHour,
        endHour: endHour,
        availableWidth: width,
        availableHeight: height,
      );

      expect(results.length, 3);
      const colWidth = width / 3;
      for (final r in results) {
        expect(r.bounds.width, closeTo(colWidth, 0.01));
      }
    });

    test('sequential non-overlapping events reuse columns', () {
      // a: 9-10, b: 9-10, c: 10-11 (c should reuse a's column)
      final events = [
        makeEvent('a', startHour: 9, endHour: 10),
        makeEvent('b', startHour: 9, endHour: 10),
        makeEvent('c', startHour: 10, endHour: 11),
      ];
      final results = TideEventLayoutEngine.layout(
        events: events,
        strategy: TideOverlapStrategy.sideBySide,
        startHour: startHour,
        endHour: endHour,
        availableWidth: width,
        availableHeight: height,
      );

      expect(results.length, 3);
      // a and b overlap → 2 columns. c starts when a ends, reuses column 0.
      final cResult = results.firstWhere((r) => r.event.id == 'c');
      // c is in its own cluster (starts exactly at a/b's end),
      // so it gets full width.
      expect(cResult.bounds.width, width);
    });

    test('Y positions map correctly for partial day range', () {
      final events = [makeEvent('a', startHour: 10, endHour: 12)];
      final results = TideEventLayoutEngine.layout(
        events: events,
        strategy: TideOverlapStrategy.sideBySide,
        startHour: 8.0,
        endHour: 18.0,
        availableWidth: width,
        availableHeight: 500.0,
      );

      final b = results.first.bounds;
      // (10-8)/(18-8) * 500 = 100
      expect(b.top, closeTo(100.0, 0.01));
      // (12-8)/(18-8) * 500 = 200, height = 200-100 = 100
      expect(b.height, closeTo(100.0, 0.01));
    });

    test('events before visible range are clamped to top', () {
      final events = [
        TideEvent(
          id: 'early',
          subject: 'Early',
          startTime: DateTime(2026, 3, 19, 6, 0),
          endTime: DateTime(2026, 3, 19, 10, 0),
        ),
      ];
      final results = TideEventLayoutEngine.layout(
        events: events,
        strategy: TideOverlapStrategy.sideBySide,
        startHour: 8.0,
        endHour: 18.0,
        availableWidth: width,
        availableHeight: 500.0,
      );

      final b = results.first.bounds;
      expect(b.top, 0.0);
    });
  });

  // -- Stack --------------------------------------------------------------

  group('stack', () {
    test('single event uses 90% width, no offset', () {
      final events = [makeEvent('a', startHour: 9, endHour: 10)];
      final results = TideEventLayoutEngine.layout(
        events: events,
        strategy: TideOverlapStrategy.stack,
        startHour: startHour,
        endHour: endHour,
        availableWidth: width,
        availableHeight: height,
      );

      expect(results.length, 1);
      final b = results.first.bounds;
      expect(b.left, 0.0);
      expect(b.width, closeTo(width * 0.9, 0.01));
    });

    test('overlapping events get progressive offsets', () {
      final events = [
        makeEvent('a', startHour: 9, endHour: 11),
        makeEvent('b', startHour: 10, endHour: 12),
      ];
      final results = TideEventLayoutEngine.layout(
        events: events,
        strategy: TideOverlapStrategy.stack,
        startHour: startHour,
        endHour: endHour,
        availableWidth: width,
        availableHeight: height,
      );

      expect(results.length, 2);
      final a = results.firstWhere((r) => r.event.id == 'a').bounds;
      final b = results.firstWhere((r) => r.event.id == 'b').bounds;

      expect(a.left, 0.0);
      expect(b.left, 8.0);
      expect(b.width, lessThan(a.width));
    });

    test('three stacked events have increasing offsets', () {
      final events = [
        makeEvent('a', startHour: 9, endHour: 12),
        makeEvent('b', startHour: 10, endHour: 13),
        makeEvent('c', startHour: 11, endHour: 14),
      ];
      final results = TideEventLayoutEngine.layout(
        events: events,
        strategy: TideOverlapStrategy.stack,
        startHour: startHour,
        endHour: endHour,
        availableWidth: width,
        availableHeight: height,
      );

      final a = results.firstWhere((r) => r.event.id == 'a').bounds;
      final b = results.firstWhere((r) => r.event.id == 'b').bounds;
      final c = results.firstWhere((r) => r.event.id == 'c').bounds;

      expect(a.left, 0.0);
      expect(b.left, 8.0);
      expect(c.left, 16.0);
      expect(c.width, lessThan(b.width));
      expect(b.width, lessThan(a.width));
    });
  });

  // -- Compress -----------------------------------------------------------

  group('compress', () {
    test('single event uses full width', () {
      final events = [makeEvent('a', startHour: 9, endHour: 10)];
      final results = TideEventLayoutEngine.layout(
        events: events,
        strategy: TideOverlapStrategy.compress,
        startHour: startHour,
        endHour: endHour,
        availableWidth: width,
        availableHeight: height,
      );

      expect(results.length, 1);
      final b = results.first.bounds;
      expect(b.left, 0.0);
      expect(b.width, closeTo(width, 0.01));
    });

    test('second column is narrower than first', () {
      final events = [
        makeEvent('a', startHour: 9, endHour: 11),
        makeEvent('b', startHour: 10, endHour: 12),
      ];
      final results = TideEventLayoutEngine.layout(
        events: events,
        strategy: TideOverlapStrategy.compress,
        startHour: startHour,
        endHour: endHour,
        availableWidth: width,
        availableHeight: height,
      );

      final a = results.firstWhere((r) => r.event.id == 'a').bounds;
      final b = results.firstWhere((r) => r.event.id == 'b').bounds;

      // First column = 100% width, second = 85%.
      expect(a.width, closeTo(width, 0.01));
      expect(b.width, closeTo(width * 0.85, 0.01));
      expect(b.left, greaterThan(a.left));
    });

    test('progressive narrowing across three columns', () {
      final events = [
        makeEvent('a', startHour: 9, endHour: 12),
        makeEvent('b', startHour: 10, endHour: 13),
        makeEvent('c', startHour: 11, endHour: 14),
      ];
      final results = TideEventLayoutEngine.layout(
        events: events,
        strategy: TideOverlapStrategy.compress,
        startHour: startHour,
        endHour: endHour,
        availableWidth: width,
        availableHeight: height,
      );

      final a = results.firstWhere((r) => r.event.id == 'a').bounds;
      final b = results.firstWhere((r) => r.event.id == 'b').bounds;
      final c = results.firstWhere((r) => r.event.id == 'c').bounds;

      expect(a.width, closeTo(width * 1.0, 0.01));
      expect(b.width, closeTo(width * 0.85, 0.01));
      expect(c.width, closeTo(width * 0.70, 0.01));
    });
  });

  // -- Edge cases ---------------------------------------------------------

  group('Edge cases', () {
    test('zero-duration events still get a non-negative height', () {
      final events = [
        TideEvent(
          id: 'zero',
          subject: 'Zero',
          startTime: DateTime(2026, 3, 19, 10, 0),
          endTime: DateTime(2026, 3, 19, 10, 0),
        ),
      ];
      final results = TideEventLayoutEngine.layout(
        events: events,
        strategy: TideOverlapStrategy.sideBySide,
        startHour: 0,
        endHour: 24,
        availableWidth: width,
        availableHeight: height,
      );

      expect(results.length, 1);
      expect(results.first.bounds.height, greaterThanOrEqualTo(0));
    });

    test('minute-level precision in time-to-Y mapping', () {
      // Event at 9:30–10:30.
      final events = [
        makeEvent('a', startHour: 9, endHour: 10, startMinute: 30, endMinute: 30),
      ];
      final results = TideEventLayoutEngine.layout(
        events: events,
        strategy: TideOverlapStrategy.sideBySide,
        startHour: 0.0,
        endHour: 24.0,
        availableWidth: width,
        availableHeight: height,
      );

      final b = results.first.bounds;
      // 9.5/24 * 960 = 380
      expect(b.top, closeTo(380.0, 0.01));
      // 1h = 40px
      expect(b.height, closeTo(40.0, 0.01));
    });

    test('large number of non-overlapping events', () {
      // One event per hour over 24 hours.
      final events = List.generate(24, (i) {
        return makeEvent('e$i', startHour: i, endHour: i + 1);
      });
      final results = TideEventLayoutEngine.layout(
        events: events,
        strategy: TideOverlapStrategy.sideBySide,
        startHour: 0,
        endHour: 24,
        availableWidth: width,
        availableHeight: height,
      );

      expect(results.length, 24);
      // Each should be full width.
      for (final r in results) {
        expect(r.bounds.width, width);
      }
    });
  });
}
