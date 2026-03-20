import 'package:flutter_test/flutter_test.dart';
import 'package:timetide/src/core/controller.dart';
import 'package:timetide/src/core/models/event.dart';
import 'package:timetide/src/interaction/selection/date_selection.dart';
import 'package:timetide/src/interaction/selection/event_selection.dart';

TideEvent _event(String id, {int hour = 9}) => TideEvent(
      id: id,
      subject: 'Event $id',
      startTime: DateTime(2024, 1, 1, hour),
      endTime: DateTime(2024, 1, 1, hour + 1),
    );

void main() {
  group('TideEventSelectionHandler', () {
    late TideController controller;
    late List<TideEvent> events;
    late TideEventSelectionHandler handler;

    setUp(() {
      controller = TideController();
      events = [_event('a', hour: 9), _event('b', hour: 10), _event('c', hour: 11), _event('d', hour: 12)];
      handler = TideEventSelectionHandler(
        controller: controller,
        allEvents: events,
      );
    });

    tearDown(() => controller.dispose());

    test('single tap selects one event', () {
      handler.handleEventTap(events[0]);
      expect(controller.selectedEvents, [events[0]]);
    });

    test('single tap replaces previous selection', () {
      handler.handleEventTap(events[0]);
      handler.handleEventTap(events[1]);
      expect(controller.selectedEvents, [events[1]]);
    });

    test('additive tap toggles event in selection', () {
      handler.handleEventTap(events[0]);
      handler.handleEventTap(events[1], isAdditive: true);
      expect(controller.selectedEvents, containsAll([events[0], events[1]]));

      // Toggle off
      handler.handleEventTap(events[0], isAdditive: true);
      expect(controller.selectedEvents, [events[1]]);
    });

    test('range select selects from last selected to target', () {
      handler.handleEventTap(events[0]); // sets last selected to 'a'
      handler.handleEventTap(events[2], isRange: true);
      expect(
        controller.selectedEvents,
        containsAll([events[0], events[1], events[2]]),
      );
    });

    test('range select works in reverse direction', () {
      handler.handleEventTap(events[3]); // last selected = 'd'
      handler.handleEventTap(events[1], isRange: true);
      expect(
        controller.selectedEvents,
        containsAll([events[1], events[2], events[3]]),
      );
    });

    test('range select without previous selection falls back to single', () {
      // No previous tap, so _lastSelectedEvent is null
      handler.handleEventTap(events[2], isRange: true);
      // isRange with null lastSelected => single select fallback
      expect(controller.selectedEvents, [events[2]]);
    });

    test('handleEmptyTap deselects all', () {
      handler.handleEventTap(events[0]);
      handler.handleEventTap(events[1], isAdditive: true);
      expect(controller.selectedEvents.length, 2);

      handler.handleEmptyTap();
      expect(controller.selectedEvents, isEmpty);
    });
  });

  group('TideDateSelectionHandler', () {
    late TideController controller;
    late TideDateSelectionHandler handler;

    setUp(() {
      controller = TideController();
      handler = TideDateSelectionHandler(controller: controller);
    });

    tearDown(() => controller.dispose());

    test('handleDateTap selects a single date', () {
      final date = DateTime(2024, 3, 15);
      handler.handleDateTap(date);
      expect(controller.selectedDate, date);
    });

    test('drag creates date range', () {
      final start = DateTime(2024, 3, 10);
      final mid = DateTime(2024, 3, 12);
      final end = DateTime(2024, 3, 15);

      handler.handleDragStart(start);
      handler.handleDragUpdate(mid);
      expect(controller.selectedDateRange!.start, start);
      expect(controller.selectedDateRange!.end, mid);

      handler.handleDragUpdate(end);
      expect(controller.selectedDateRange!.start, start);
      expect(controller.selectedDateRange!.end, end);

      handler.handleDragEnd();
    });

    test('drag in reverse direction normalizes range', () {
      final end = DateTime(2024, 3, 10);
      final start = DateTime(2024, 3, 15);

      handler.handleDragStart(start);
      handler.handleDragUpdate(end);
      // end < start, so range should be normalized
      expect(controller.selectedDateRange!.start, end);
      expect(controller.selectedDateRange!.end, start);

      handler.handleDragEnd();
    });

    test('handleDragUpdate without start is a no-op', () {
      handler.handleDragUpdate(DateTime(2024, 3, 10));
      expect(controller.selectedDateRange, isNull);
    });
  });
}
