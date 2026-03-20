import 'package:flutter_test/flutter_test.dart';
import 'package:timetide/src/core/controller.dart';
import 'package:timetide/src/core/datasource_in_memory.dart';
import 'package:timetide/src/core/models/conflict.dart';
import 'package:timetide/src/core/models/date_time_range.dart';
import 'package:timetide/src/core/models/event.dart';
import 'package:timetide/src/core/models/event_changes.dart';
import 'package:timetide/src/core/models/view.dart';
import 'package:timetide/src/core/presets.dart';

void main() {
  // ─── Helpers ──────────────────────────────────────────────

  final june15 = DateTime(2024, 6, 15); // Saturday
  final june17 = DateTime(2024, 6, 17); // Monday

  TideEvent makeEvent({
    String id = 'evt-1',
    String subject = 'Meeting',
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return TideEvent(
      id: id,
      subject: subject,
      startTime: startTime ?? DateTime(2024, 6, 15, 9, 0),
      endTime: endTime ?? DateTime(2024, 6, 15, 10, 0),
    );
  }

  // ─── Construction ────────────────────────────────────────

  group('TideController construction', () {
    test('defaults', () {
      final controller = TideController();
      addTearDown(controller.dispose);

      expect(controller.currentView, TideView.week);
      expect(controller.displayDate.day, DateTime.now().day);
      expect(controller.selectedEvents, isEmpty);
      expect(controller.zoomLevel, 1.0);
      expect(controller.minZoomLevel, 0.5);
      expect(controller.maxZoomLevel, 3.0);
      expect(controller.undoHistoryLimit, 20);
      expect(controller.canUndo, isFalse);
      expect(controller.canRedo, isFalse);
      expect(controller.selectedDate, isNull);
      expect(controller.selectedDateRange, isNull);
      expect(controller.visibleResourceIds, isEmpty);
    });

    test('accepts initial values', () {
      final controller = TideController(
        initialView: TideView.month,
        initialDate: june15,
        undoHistoryLimit: 10,
        minZoomLevel: 0.25,
        maxZoomLevel: 5.0,
      );
      addTearDown(controller.dispose);

      expect(controller.currentView, TideView.month);
      expect(controller.displayDate, june15);
      expect(controller.undoHistoryLimit, 10);
      expect(controller.minZoomLevel, 0.25);
      expect(controller.maxZoomLevel, 5.0);
    });

    test('creates internal datasource when none provided', () {
      final controller = TideController();
      addTearDown(controller.dispose);
      expect(controller.datasource, isA<TideInMemoryDatasource>());
    });

    test('uses provided datasource', () {
      final ds = TideInMemoryDatasource();
      final controller = TideController(datasource: ds);
      addTearDown(controller.dispose);
      addTearDown(ds.dispose);

      expect(controller.datasource, same(ds));
    });
  });

  // ─── Navigation ──────────────────────────────────────────

  group('Navigation', () {
    late TideController controller;

    setUp(() {
      controller = TideController(
        initialDate: june17, // Monday 2024-06-17
        initialView: TideView.day,
      );
    });

    tearDown(() {
      controller.dispose();
    });

    test('displayDate setter notifies listeners', () {
      var notified = false;
      controller.addListener(() => notified = true);
      controller.displayDate = DateTime(2024, 7, 1);
      expect(notified, isTrue);
    });

    test('displayDate setter does not notify on same value', () {
      var notified = false;
      controller.displayDate = june17;
      controller.addListener(() => notified = true);
      controller.displayDate = june17;
      expect(notified, isFalse);
    });

    test('forward() — day view steps by 1 day', () {
      controller.currentView = TideView.day;
      controller.displayDate = june17;
      controller.forward();
      expect(controller.displayDate, DateTime(2024, 6, 18));
    });

    test('backward() — day view steps back 1 day', () {
      controller.currentView = TideView.day;
      controller.displayDate = june17;
      controller.backward();
      expect(controller.displayDate, DateTime(2024, 6, 16));
    });

    test('forward() — week view steps by 7 days', () {
      controller.currentView = TideView.week;
      controller.displayDate = june17;
      controller.forward();
      expect(controller.displayDate, DateTime(2024, 6, 24));
    });

    test('backward() — week view steps back 7 days', () {
      controller.currentView = TideView.week;
      controller.displayDate = june17;
      controller.backward();
      expect(controller.displayDate, DateTime(2024, 6, 10));
    });

    test('forward() — workWeek view steps by 5 days', () {
      controller.currentView = TideView.workWeek;
      controller.displayDate = june17;
      controller.forward();
      expect(controller.displayDate, DateTime(2024, 6, 22));
    });

    test('forward() — month view steps by 1 month', () {
      controller.currentView = TideView.month;
      controller.displayDate = june17;
      controller.forward();
      expect(controller.displayDate.month, 7);
      expect(controller.displayDate.day, 17);
    });

    test('forward() — year view steps by 1 year', () {
      controller.currentView = TideView.year;
      controller.displayDate = june17;
      controller.forward();
      expect(controller.displayDate.year, 2025);
    });

    test('forward() — multiWeek view steps by numberOfWeeksInMultiWeek * 7',
        () {
      final c = TideController(
        initialDate: june17,
        initialView: TideView.multiWeek,
        numberOfWeeksInMultiWeek: 3,
      );
      addTearDown(c.dispose);
      c.forward();
      expect(c.displayDate, DateTime(2024, 7, 8)); // 17 + 21
    });

    test('forward() — timelineDay steps by 1 day', () {
      controller.currentView = TideView.timelineDay;
      controller.displayDate = june17;
      controller.forward();
      expect(controller.displayDate, DateTime(2024, 6, 18));
    });

    test('forward() — timelineWeek steps by 7 days', () {
      controller.currentView = TideView.timelineWeek;
      controller.displayDate = june17;
      controller.forward();
      expect(controller.displayDate, DateTime(2024, 6, 24));
    });

    test('forward() — timelineWorkWeek steps by 5 days', () {
      controller.currentView = TideView.timelineWorkWeek;
      controller.displayDate = june17;
      controller.forward();
      expect(controller.displayDate, DateTime(2024, 6, 22));
    });

    test('forward() — timelineMonth steps by 1 month', () {
      controller.currentView = TideView.timelineMonth;
      controller.displayDate = june17;
      controller.forward();
      expect(controller.displayDate.month, 7);
    });

    test('forward() — schedule steps by 7 days', () {
      controller.currentView = TideView.schedule;
      controller.displayDate = june17;
      controller.forward();
      expect(controller.displayDate, DateTime(2024, 6, 24));
    });

    test('today() sets displayDate to today', () {
      controller.displayDate = DateTime(2020, 1, 1);
      controller.today();
      final now = DateTime.now();
      expect(controller.displayDate.year, now.year);
      expect(controller.displayDate.month, now.month);
      expect(controller.displayDate.day, now.day);
    });

    test('animateToDate sets displayDate', () {
      controller.animateToDate(DateTime(2025, 1, 1));
      expect(controller.displayDate, DateTime(2025, 1, 1));
    });
  });

  // ─── Visible Date Range ──────────────────────────────────

  group('visibleDateRange', () {
    test('day view — single day', () {
      final c = TideController(
        initialDate: june17,
        initialView: TideView.day,
      );
      addTearDown(c.dispose);

      final range = c.visibleDateRange;
      expect(range.start, DateTime(2024, 6, 17));
      expect(range.end, DateTime(2024, 6, 18));
    });

    test('week view — Monday to next Monday', () {
      final c = TideController(
        initialDate: june17, // Monday
        initialView: TideView.week,
      );
      addTearDown(c.dispose);

      final range = c.visibleDateRange;
      expect(range.start, DateTime(2024, 6, 17));
      expect(range.end, DateTime(2024, 6, 24));
    });

    test('workWeek view — Monday to Saturday', () {
      final c = TideController(
        initialDate: june17,
        initialView: TideView.workWeek,
      );
      addTearDown(c.dispose);

      final range = c.visibleDateRange;
      expect(range.start, DateTime(2024, 6, 17));
      expect(range.end, DateTime(2024, 6, 22));
    });

    test('month view — first to last of month', () {
      final c = TideController(
        initialDate: june17,
        initialView: TideView.month,
      );
      addTearDown(c.dispose);

      final range = c.visibleDateRange;
      expect(range.start, DateTime(2024, 6));
      expect(range.end, DateTime(2024, 7));
    });

    test('year view — January 1 to January 1 next year', () {
      final c = TideController(
        initialDate: june17,
        initialView: TideView.year,
      );
      addTearDown(c.dispose);

      final range = c.visibleDateRange;
      expect(range.start, DateTime(2024));
      expect(range.end, DateTime(2025));
    });

    test('schedule view — 7-day window', () {
      final c = TideController(
        initialDate: june17,
        initialView: TideView.schedule,
      );
      addTearDown(c.dispose);

      final range = c.visibleDateRange;
      expect(range.start, DateTime(2024, 6, 17));
      expect(range.end, DateTime(2024, 6, 24));
    });

    test('multiWeek view — correct number of weeks', () {
      final c = TideController(
        initialDate: june17,
        initialView: TideView.multiWeek,
        numberOfWeeksInMultiWeek: 4,
      );
      addTearDown(c.dispose);

      final range = c.visibleDateRange;
      expect(range.start, DateTime(2024, 6, 17));
      expect(range.end, DateTime(2024, 7, 15)); // 17 + 28
    });
  });

  // ─── View Management ─────────────────────────────────────

  group('View management', () {
    test('currentView setter notifies listeners', () {
      final controller = TideController();
      addTearDown(controller.dispose);

      var notified = false;
      controller.addListener(() => notified = true);
      controller.currentView = TideView.month;
      expect(notified, isTrue);
      expect(controller.currentView, TideView.month);
    });

    test('currentView setter skips notification on same value', () {
      final controller = TideController(initialView: TideView.day);
      addTearDown(controller.dispose);

      var notified = false;
      controller.addListener(() => notified = true);
      controller.currentView = TideView.day;
      expect(notified, isFalse);
    });

    test('currentViewNotifier updates', () {
      final controller = TideController();
      addTearDown(controller.dispose);

      controller.currentView = TideView.year;
      expect(controller.currentViewNotifier.value, TideView.year);
    });
  });

  // ─── Selection ───────────────────────────────────────────

  group('Selection', () {
    late TideController controller;

    setUp(() {
      controller = TideController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('selectEvent replaces selection', () {
      final e1 = makeEvent(id: 'e1');
      final e2 = makeEvent(id: 'e2');

      controller.selectEvent(e1);
      expect(controller.selectedEvents, [e1]);

      controller.selectEvent(e2);
      expect(controller.selectedEvents, [e2]);
    });

    test('selectEvent additive adds to selection', () {
      final e1 = makeEvent(id: 'e1');
      final e2 = makeEvent(id: 'e2');

      controller.selectEvent(e1);
      controller.selectEvent(e2, additive: true);
      expect(controller.selectedEvents, containsAll([e1, e2]));
    });

    test('selectEvent additive toggles off already-selected event', () {
      final e1 = makeEvent(id: 'e1');

      controller.selectEvent(e1);
      controller.selectEvent(e1, additive: true);
      expect(controller.selectedEvents, isEmpty);
    });

    test('deselectAll clears everything', () {
      controller.selectEvent(makeEvent());
      controller.selectDate(june17);

      controller.deselectAll();
      expect(controller.selectedEvents, isEmpty);
      expect(controller.selectedDate, isNull);
      expect(controller.selectedDateRange, isNull);
    });

    test('deselectAll with no selection does not notify', () {
      var notified = false;
      controller.addListener(() => notified = true);
      controller.deselectAll();
      expect(notified, isFalse);
    });

    test('selectDate sets selectedDate and clears date range', () {
      controller.selectDateRange(june15, june17);
      controller.selectDate(june17);
      expect(controller.selectedDate, june17);
      expect(controller.selectedDateRange, isNull);
    });

    test('selectDateRange sets range and clears selected date', () {
      controller.selectDate(june17);
      controller.selectDateRange(june15, june17);
      expect(controller.selectedDateRange!.start, june15);
      expect(controller.selectedDateRange!.end, june17);
      expect(controller.selectedDate, isNull);
    });

    test('selectedEventsNotifier reflects changes', () {
      final event = makeEvent();
      controller.selectEvent(event);
      expect(controller.selectedEventsNotifier.value, [event]);
    });
  });

  // ─── Undo / Redo ─────────────────────────────────────────

  group('Undo / Redo', () {
    late TideInMemoryDatasource datasource;
    late TideController controller;

    setUp(() {
      datasource = TideInMemoryDatasource();
      controller = TideController(datasource: datasource);
    });

    tearDown(() {
      controller.dispose();
      datasource.dispose();
    });

    test('addEvent can be undone', () async {
      final event = makeEvent(id: 'e1');
      controller.addEvent(event);
      expect(controller.canUndo, isTrue);

      controller.undo();
      await Future<void>.delayed(Duration.zero);

      final events = await datasource.getEvents(
        DateTime(2024),
        DateTime(2025),
      );
      expect(events, isEmpty);
    });

    test('undo then redo restores the event', () async {
      final event = makeEvent(id: 'e1');
      controller.addEvent(event);

      controller.undo();
      expect(controller.canRedo, isTrue);

      controller.redo();
      await Future<void>.delayed(Duration.zero);

      final events = await datasource.getEvents(
        DateTime(2024),
        DateTime(2025),
      );
      expect(events, hasLength(1));
      expect(events.first.id, 'e1');
    });

    test('undo with empty stack is no-op', () {
      expect(controller.canUndo, isFalse);
      controller.undo(); // should not throw
    });

    test('redo with empty stack is no-op', () {
      expect(controller.canRedo, isFalse);
      controller.redo(); // should not throw
    });

    test('new action clears redo stack', () {
      controller.addEvent(makeEvent(id: 'e1'));
      controller.undo();
      expect(controller.canRedo, isTrue);

      controller.addEvent(makeEvent(id: 'e2'));
      expect(controller.canRedo, isFalse);
    });

    test('undoHistoryLimit trims old entries', () {
      controller.undoHistoryLimit = 3;
      for (var i = 0; i < 5; i++) {
        controller.addEvent(makeEvent(id: 'e$i'));
      }
      // Only the last 3 should be on the undo stack.
      var undoCount = 0;
      while (controller.canUndo) {
        controller.undo();
        undoCount++;
      }
      expect(undoCount, 3);
    });
  });

  // ─── Zoom ────────────────────────────────────────────────

  group('Zoom', () {
    late TideController controller;

    setUp(() {
      controller = TideController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('zoomLevel setter clamps to range', () {
      controller.zoomLevel = 0.1;
      expect(controller.zoomLevel, controller.minZoomLevel);

      controller.zoomLevel = 10.0;
      expect(controller.zoomLevel, controller.maxZoomLevel);
    });

    test('zoomLevel setter notifies listeners', () {
      var notified = false;
      controller.addListener(() => notified = true);
      controller.zoomLevel = 2.0;
      expect(notified, isTrue);
    });

    test('zoomLevel setter skips notification on same value', () {
      controller.zoomLevel = 1.5;
      var notified = false;
      controller.addListener(() => notified = true);
      controller.zoomLevel = 1.5;
      expect(notified, isFalse);
    });

    test('zoomLevelNotifier reflects changes', () {
      controller.zoomLevel = 2.5;
      expect(controller.zoomLevelNotifier.value, 2.5);
    });
  });

  // ─── Resource Management ─────────────────────────────────

  group('Resource management', () {
    late TideController controller;

    setUp(() {
      controller = TideController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('showResource adds to visible set', () {
      controller.showResource('r1');
      controller.showResource('r2');
      expect(controller.visibleResourceIds, {'r1', 'r2'});
    });

    test('hideResource removes from visible set', () {
      controller.showResource('r1');
      controller.showResource('r2');
      controller.hideResource('r1');
      expect(controller.visibleResourceIds, {'r2'});
    });

    test('visibleResourcesNotifier reflects changes', () {
      controller.showResource('r1');
      expect(controller.visibleResourcesNotifier.value, {'r1'});
    });

    test('reorderResources sets resource order', () {
      controller.reorderResources(['r3', 'r1', 'r2']);
      expect(controller.resourceOrder, ['r3', 'r1', 'r2']);
    });

    test('reorderResources notifies listeners', () {
      var notified = false;
      controller.addListener(() => notified = true);
      controller.reorderResources(['r1']);
      expect(notified, isTrue);
    });
  });

  // ─── Event Management ────────────────────────────────────

  group('Event management', () {
    late TideInMemoryDatasource datasource;
    late TideController controller;

    setUp(() {
      datasource = TideInMemoryDatasource();
      controller = TideController(datasource: datasource);
    });

    tearDown(() {
      controller.dispose();
      datasource.dispose();
    });

    test('addEvent delegates to datasource', () async {
      controller.addEvent(makeEvent(id: 'e1'));
      final events = await datasource.getEvents(
        DateTime(2024),
        DateTime(2025),
      );
      expect(events, hasLength(1));
    });

    test('updateEvent delegates to datasource', () async {
      datasource.addEvent(makeEvent(id: 'e1', subject: 'Original'));
      controller.updateEvent(makeEvent(id: 'e1', subject: 'Updated'));

      // Wait for the async capture.
      await Future<void>.delayed(Duration.zero);

      final events = await datasource.getEvents(
        DateTime(2024),
        DateTime(2025),
      );
      expect(events.first.subject, 'Updated');
    });

    test('removeEvent delegates to datasource', () async {
      datasource.addEvent(makeEvent(id: 'e1'));
      controller.removeEvent('e1');

      await Future<void>.delayed(Duration.zero);

      final events = await datasource.getEvents(
        DateTime(2024),
        DateTime(2025),
      );
      expect(events, isEmpty);
    });
  });

  // ─── Recurrence Editing Stubs ────────────────────────────

  group('Recurrence editing stubs', () {
    late TideController controller;

    setUp(() {
      controller = TideController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('editOccurrence throws UnimplementedError', () {
      expect(
        () => controller.editOccurrence(
          seriesEvent: makeEvent(),
          occurrenceDate: june17,
          changes: const TideEventChanges(subject: 'New'),
        ),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('deleteOccurrence throws UnimplementedError', () {
      expect(
        () => controller.deleteOccurrence(
          seriesEvent: makeEvent(),
          occurrenceDate: june17,
        ),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('editThisAndFollowing throws UnimplementedError', () {
      expect(
        () => controller.editThisAndFollowing(
          seriesEvent: makeEvent(),
          fromDate: june17,
          changes: const TideEventChanges(subject: 'New'),
        ),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('editSeries throws UnimplementedError', () {
      expect(
        () => controller.editSeries(
          seriesEvent: makeEvent(),
          changes: const TideEventChanges(subject: 'New'),
        ),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('checkRecurrenceConflicts throws UnimplementedError', () {
      expect(
        () => controller.checkRecurrenceConflicts(
          event: makeEvent(),
          checkRange: TideDateTimeRange(start: june15, end: june17),
        ),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });

  // ─── State Persistence ───────────────────────────────────

  group('State persistence', () {
    test('saveState captures all relevant fields', () {
      final controller = TideController(
        initialDate: june17,
        initialView: TideView.timelineDay,
      );
      addTearDown(controller.dispose);
      controller.zoomLevel = 1.5;
      controller.showResource('r1');

      final state = controller.saveState();
      expect(state['displayDate'], june17.toIso8601String());
      expect(state['currentView'], 'timelineDay');
      expect(state['zoomLevel'], 1.5);
      expect(state['visibleResourceIds'], ['r1']);
    });

    test('restoreState restores all fields', () {
      final controller = TideController();
      addTearDown(controller.dispose);

      controller.restoreState({
        'displayDate': '2024-06-17T00:00:00.000',
        'currentView': 'month',
        'zoomLevel': 2.0,
        'visibleResourceIds': ['r1', 'r2'],
      });

      expect(controller.displayDate, DateTime(2024, 6, 17));
      expect(controller.currentView, TideView.month);
      expect(controller.zoomLevel, 2.0);
      expect(controller.visibleResourceIds, {'r1', 'r2'});
    });

    test('restoreState ignores unknown keys', () {
      final controller = TideController(initialView: TideView.day);
      addTearDown(controller.dispose);

      controller.restoreState({'unknownKey': 42});
      expect(controller.currentView, TideView.day);
    });

    test('restoreState handles invalid view name gracefully', () {
      final controller = TideController(initialView: TideView.day);
      addTearDown(controller.dispose);

      controller.restoreState({'currentView': 'notAView'});
      expect(controller.currentView, TideView.day);
    });

    test('saveState roundtrip preserves state', () {
      final c1 = TideController(
        initialDate: june17,
        initialView: TideView.schedule,
      );
      addTearDown(c1.dispose);
      c1.zoomLevel = 2.5;

      final state = c1.saveState();

      final c2 = TideController();
      addTearDown(c2.dispose);
      c2.restoreState(state);

      expect(c2.displayDate, c1.displayDate);
      expect(c2.currentView, c1.currentView);
      expect(c2.zoomLevel, c1.zoomLevel);
    });
  });

  // ─── Datasource Change Listening ─────────────────────────

  group('Datasource change listening', () {
    test('controller notifies on datasource changes', () async {
      final datasource = TideInMemoryDatasource();
      final controller = TideController(datasource: datasource);
      addTearDown(() {
        controller.dispose();
        datasource.dispose();
      });

      var notified = false;
      controller.addListener(() => notified = true);

      datasource.addEvent(makeEvent());
      await Future<void>.delayed(Duration.zero);

      expect(notified, isTrue);
    });
  });

  // ─── Dispose ─────────────────────────────────────────────

  group('Dispose', () {
    test('dispose does not throw when called once', () {
      final controller = TideController();
      expect(() => controller.dispose(), returnsNormally);
    });

    test('double dispose does not throw', () {
      final controller = TideController();
      controller.dispose();
      expect(() => controller.dispose(), returnsNormally);
    });

    test('disposes owned internal datasource', () {
      final controller = TideController();
      final ds = controller.datasource;
      controller.dispose();

      // After disposal, the datasource stream should be done.
      expectLater(ds.changes, emitsDone);
    });

    test('does not dispose externally provided datasource', () async {
      final ds = TideInMemoryDatasource();
      final controller = TideController(datasource: ds);
      controller.dispose();

      // External datasource should still work.
      ds.addEvent(makeEvent());
      final events = await ds.getEvents(DateTime(2024), DateTime(2025));
      expect(events, hasLength(1));
      ds.dispose();
    });
  });

  // ─── TideConflict ────────────────────────────────────────

  group('TideConflict', () {
    test('construction and accessors', () {
      final a = makeEvent(id: 'a');
      final b = makeEvent(id: 'b');
      final conflict = TideConflict(
        eventA: a,
        eventB: b,
        overlapStart: DateTime(2024, 6, 15, 9, 0),
        overlapEnd: DateTime(2024, 6, 15, 10, 0),
      );

      expect(conflict.eventA, a);
      expect(conflict.eventB, b);
      expect(conflict.overlapDuration, const Duration(hours: 1));
    });

    test('toString contains event IDs', () {
      final conflict = TideConflict(
        eventA: makeEvent(id: 'a'),
        eventB: makeEvent(id: 'b'),
        overlapStart: DateTime(2024, 6, 15, 9, 0),
        overlapEnd: DateTime(2024, 6, 15, 10, 0),
      );
      expect(conflict.toString(), contains('a'));
      expect(conflict.toString(), contains('b'));
    });
  });

  // ─── TidePreset ──────────────────────────────────────────

  group('TidePreset', () {
    test('every preset returns a valid config', () {
      for (final preset in TidePreset.values) {
        final config = preset.config;
        expect(config.initialView, isA<TideView>());
        expect(config.timeSlotDuration.inMinutes, greaterThan(0));
        expect(config.workDayEnd, greaterThanOrEqualTo(config.workDayStart));
      }
    });

    test('salonDay preset has expected values', () {
      final config = TidePreset.salonDay.config;
      expect(config.initialView, TideView.timelineDay);
      expect(config.timeSlotDuration, const Duration(minutes: 15));
      expect(config.resourcesEnabled, isTrue);
    });

    test('teamPlanning preset uses timelineWeek', () {
      final config = TidePreset.teamPlanning.config;
      expect(config.initialView, TideView.timelineWeek);
      expect(config.resourcesEnabled, isTrue);
    });

    test('monthOverview preset uses month view', () {
      final config = TidePreset.monthOverview.config;
      expect(config.initialView, TideView.month);
      expect(config.resourcesEnabled, isFalse);
    });

    test('schoolTimetable hides weekends', () {
      final config = TidePreset.schoolTimetable.config;
      expect(config.showWeekends, isFalse);
      expect(config.initialView, TideView.workWeek);
    });

    test('clinicSchedule has higher default zoom', () {
      final config = TidePreset.clinicSchedule.config;
      expect(config.defaultZoomLevel, 1.5);
      expect(config.timeSlotDuration, const Duration(minutes: 10));
    });

    test('conference preset', () {
      final config = TidePreset.conference.config;
      expect(config.initialView, TideView.timelineWeek);
      expect(config.workDayEnd, 22);
    });
  });

  // ─── ValueNotifier granularity ───────────────────────────

  group('ValueNotifier granularity', () {
    test('displayDateNotifier updates independently', () {
      final controller = TideController(initialDate: june17);
      addTearDown(controller.dispose);

      var notifierChanged = false;
      controller.displayDateNotifier.addListener(() {
        notifierChanged = true;
      });

      controller.displayDate = DateTime(2024, 7, 1);
      expect(notifierChanged, isTrue);
    });

    test('zoomLevelNotifier updates independently', () {
      final controller = TideController();
      addTearDown(controller.dispose);

      var notifierChanged = false;
      controller.zoomLevelNotifier.addListener(() {
        notifierChanged = true;
      });

      controller.zoomLevel = 2.0;
      expect(notifierChanged, isTrue);
    });
  });
}
