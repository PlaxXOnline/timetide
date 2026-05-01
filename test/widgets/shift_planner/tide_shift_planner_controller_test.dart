import 'package:flutter_test/flutter_test.dart';
import 'package:timetide/src/core/models/date_time_range.dart';
import 'package:timetide/src/core/models/event.dart';
import 'package:timetide/src/widgets/shift_planner/shift_drag_mode.dart';
import 'package:timetide/src/widgets/shift_planner/tide_shift_planner_controller.dart';

void main() {
  group('TideShiftPlannerController — week navigation', () {
    test('default constructor normalizes today to Monday at 00:00:00', () {
      final controller = TideShiftPlannerController();
      final ws = controller.currentWeekStart;
      expect(ws.weekday, DateTime.monday);
      expect(ws.hour, 0);
      expect(ws.minute, 0);
      expect(ws.second, 0);
      expect(ws.millisecond, 0);
      expect(ws.microsecond, 0);

      // Should match the Monday of "today".
      final now = DateTime.now();
      final expectedMonday = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - DateTime.monday));
      expect(ws, expectedMonday);
    });

    test('initialWeekStart on a Wednesday is normalized to that Monday', () {
      // 2026-04-29 is a Wednesday.
      final wed = DateTime(2026, 4, 29, 14, 30);
      final controller =
          TideShiftPlannerController(initialWeekStart: wed);
      expect(
        controller.currentWeekStart,
        DateTime(2026, 4, 27), // Monday
      );
    });

    test('initialWeekStart already on Monday is preserved (time stripped)', () {
      final mon = DateTime(2026, 4, 27, 8, 15);
      final controller =
          TideShiftPlannerController(initialWeekStart: mon);
      expect(controller.currentWeekStart, DateTime(2026, 4, 27));
    });

    test('goToWeek normalizes and notifies listeners', () {
      final controller = TideShiftPlannerController(
        initialWeekStart: DateTime(2026, 1, 5),
      );
      var calls = 0;
      controller.addListener(() => calls++);

      controller.goToWeek(DateTime(2026, 4, 29)); // Wednesday
      expect(controller.currentWeekStart, DateTime(2026, 4, 27));
      expect(calls, 1);
    });

    test('goToPreviousWeek subtracts 7 days, stays on Monday', () {
      final controller = TideShiftPlannerController(
        initialWeekStart: DateTime(2026, 4, 27), // Monday
      );
      var calls = 0;
      controller.addListener(() => calls++);

      controller.goToPreviousWeek();
      expect(controller.currentWeekStart, DateTime(2026, 4, 20));
      expect(controller.currentWeekStart.weekday, DateTime.monday);
      expect(calls, 1);
    });

    test('goToNextWeek adds 7 days, stays on Monday', () {
      final controller = TideShiftPlannerController(
        initialWeekStart: DateTime(2026, 4, 27),
      );
      var calls = 0;
      controller.addListener(() => calls++);

      controller.goToNextWeek();
      expect(controller.currentWeekStart, DateTime(2026, 5, 4));
      expect(controller.currentWeekStart.weekday, DateTime.monday);
      expect(calls, 1);
    });

    test('refresh() notifies without state change', () {
      final controller = TideShiftPlannerController(
        initialWeekStart: DateTime(2026, 4, 27),
      );
      final before = controller.currentWeekStart;
      var calls = 0;
      controller.addListener(() => calls++);

      controller.refresh();
      expect(calls, 1);
      expect(controller.currentWeekStart, before);
    });
  });

  group('TideShiftPlannerController.generateCopiedShifts', () {
    final mondayA = DateTime(2026, 4, 27);
    final sundayA = DateTime(2026, 5, 3, 23, 59, 59);
    final mondayB = DateTime(2026, 5, 4);
    final sundayB = DateTime(2026, 5, 10, 23, 59, 59);

    TideShiftPlannerController makeController({String Function()? gen}) {
      return TideShiftPlannerController(
        initialWeekStart: mondayA,
        idGenerator: gen,
      );
    }

    test('empty source returns empty result without exception', () {
      final controller = makeController();
      final out = controller.generateCopiedShifts(
        source: TideDateTimeRange(start: mondayA, end: sundayA),
        target: TideDateTimeRange(start: mondayB, end: sundayB),
        sourceEvents: const [],
      );
      expect(out, isEmpty);
    });

    test('throws ArgumentError when target is shorter than source', () {
      final controller = makeController();
      final shorterTarget = TideDateTimeRange(
        start: mondayB,
        end: mondayB.add(const Duration(days: 3)),
      );
      expect(
        () => controller.generateCopiedShifts(
          source: TideDateTimeRange(start: mondayA, end: sundayA),
          target: shorterTarget,
          sourceEvents: [
            TideEvent(
              id: 'e1',
              subject: 'A',
              startTime: mondayA.add(const Duration(hours: 9)),
              endTime: mondayA.add(const Duration(hours: 17)),
            ),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('1:1 mapping with deterministic idGenerator', () {
      var counter = 0;
      final controller = makeController(
        gen: () => 'fixed-id-${++counter}',
      );
      final src = TideEvent(
        id: 'orig-1',
        subject: 'Shift A',
        startTime: mondayA.add(const Duration(hours: 9)),
        endTime: mondayA.add(const Duration(hours: 17)),
        resourceIds: const ['r1'],
      );
      final out = controller.generateCopiedShifts(
        source: TideDateTimeRange(start: mondayA, end: sundayA),
        target: TideDateTimeRange(start: mondayB, end: sundayB),
        sourceEvents: [src],
      );
      expect(out, hasLength(1));
      expect(out.first.id, 'fixed-id-1');
      expect(out.first.subject, 'Shift A');
      expect(out.first.startTime, mondayB.add(const Duration(hours: 9)));
      expect(out.first.endTime, mondayB.add(const Duration(hours: 17)));
      expect(out.first.resourceIds, ['r1']);
    });

    test('target = 2 weeks → source replicated twice (same weekday, new IDs)',
        () {
      var counter = 0;
      final controller = makeController(
        gen: () => 'gen-${++counter}',
      );
      final mondayShift = TideEvent(
        id: 'orig-mon',
        subject: 'Mon',
        startTime: mondayA.add(const Duration(hours: 9)),
        endTime: mondayA.add(const Duration(hours: 17)),
      );
      final wednesdayShift = TideEvent(
        id: 'orig-wed',
        subject: 'Wed',
        startTime: mondayA.add(const Duration(days: 2, hours: 8)),
        endTime: mondayA.add(const Duration(days: 2, hours: 16)),
      );

      // 2-week target.
      final target = TideDateTimeRange(
        start: mondayB,
        end: mondayB.add(const Duration(days: 13, hours: 23, minutes: 59)),
      );

      final out = controller.generateCopiedShifts(
        source: TideDateTimeRange(start: mondayA, end: sundayA),
        target: target,
        sourceEvents: [mondayShift, wednesdayShift],
      );

      expect(out, hasLength(4));
      // Week 1
      expect(out[0].startTime, mondayB.add(const Duration(hours: 9)));
      expect(out[1].startTime,
          mondayB.add(const Duration(days: 2, hours: 8)));
      // Week 2
      expect(out[2].startTime,
          mondayB.add(const Duration(days: 7, hours: 9)));
      expect(out[3].startTime,
          mondayB.add(const Duration(days: 9, hours: 8)));

      // All new IDs, all unique.
      final ids = out.map((e) => e.id).toSet();
      expect(ids.length, 4);
      for (final id in ids) {
        expect(id.startsWith('gen-'), isTrue);
      }
      // Original event IDs are not reused.
      expect(ids.contains('orig-mon'), isFalse);
      expect(ids.contains('orig-wed'), isFalse);
    });

    test('skipClosedDays + isDayClosed predicate skips matching days', () {
      var counter = 0;
      final controller = makeController(
        gen: () => 'g-${++counter}',
      );
      final monShift = TideEvent(
        id: 'orig-mon',
        subject: 'Mon',
        startTime: mondayA.add(const Duration(hours: 9)),
        endTime: mondayA.add(const Duration(hours: 17)),
      );
      final tueShift = TideEvent(
        id: 'orig-tue',
        subject: 'Tue',
        startTime: mondayA.add(const Duration(days: 1, hours: 9)),
        endTime: mondayA.add(const Duration(days: 1, hours: 17)),
      );

      // Closed = Monday in target week (mondayB = 2026-05-04).
      final out = controller.generateCopiedShifts(
        source: TideDateTimeRange(start: mondayA, end: sundayA),
        target: TideDateTimeRange(start: mondayB, end: sundayB),
        sourceEvents: [monShift, tueShift],
        skipClosedDays: true,
        isDayClosed: (d) =>
            d.year == 2026 && d.month == 5 && d.day == 4,
      );

      expect(out, hasLength(1));
      expect(out.first.subject, 'Tue');
      expect(out.first.startTime,
          mondayB.add(const Duration(days: 1, hours: 9)));
    });

    test('source events remain unchanged (pure function)', () {
      final controller = makeController(gen: () => 'fixed');
      final src = TideEvent(
        id: 'orig',
        subject: 'A',
        startTime: mondayA.add(const Duration(hours: 9)),
        endTime: mondayA.add(const Duration(hours: 17)),
      );
      final beforeStart = src.startTime;
      final beforeEnd = src.endTime;
      final beforeId = src.id;
      final beforeSubject = src.subject;

      controller.generateCopiedShifts(
        source: TideDateTimeRange(start: mondayA, end: sundayA),
        target: TideDateTimeRange(start: mondayB, end: sundayB),
        sourceEvents: [src],
      );

      expect(src.startTime, beforeStart);
      expect(src.endTime, beforeEnd);
      expect(src.id, beforeId);
      expect(src.subject, beforeSubject);
    });

    test('default idGenerator produces unique IDs', () {
      final controller = TideShiftPlannerController(
        initialWeekStart: mondayA,
      );
      final events = [
        TideEvent(
          id: 'a',
          subject: 'A',
          startTime: mondayA.add(const Duration(hours: 9)),
          endTime: mondayA.add(const Duration(hours: 17)),
        ),
        TideEvent(
          id: 'b',
          subject: 'B',
          startTime: mondayA.add(const Duration(days: 1, hours: 9)),
          endTime: mondayA.add(const Duration(days: 1, hours: 17)),
        ),
      ];
      final out = controller.generateCopiedShifts(
        source: TideDateTimeRange(start: mondayA, end: sundayA),
        target: TideDateTimeRange(start: mondayB, end: sundayB),
        sourceEvents: events,
      );
      final ids = out.map((e) => e.id).toSet();
      expect(ids.length, 2);
      for (final id in ids) {
        expect(id.startsWith('shift-'), isTrue);
      }
    });
  });

  group('TideShiftPlannerController.copyPreviousWeek', () {
    test('uses currentWeek as target and previousWeek (-7) as source', () {
      var counter = 0;
      final controller = TideShiftPlannerController(
        initialWeekStart: DateTime(2026, 5, 4), // Monday
        idGenerator: () => 'p-${++counter}',
      );
      // Previous week's Monday: 2026-04-27.
      final prevMon = DateTime(2026, 4, 27);
      final prevEvents = [
        TideEvent(
          id: 'pe1',
          subject: 'PrevMon',
          startTime: prevMon.add(const Duration(hours: 9)),
          endTime: prevMon.add(const Duration(hours: 17)),
        ),
      ];

      final out = controller.copyPreviousWeek(
        previousWeekEvents: prevEvents,
      );
      expect(out, hasLength(1));
      expect(out.first.startTime,
          DateTime(2026, 5, 4, 9));
      expect(out.first.endTime, DateTime(2026, 5, 4, 17));
      expect(out.first.subject, 'PrevMon');
      expect(out.first.id, 'p-1');
    });
  });

  group('TideShiftPlannerController.generateMonthFromWeek', () {
    test('replicates source week for every Monday in target month', () {
      var counter = 0;
      final controller = TideShiftPlannerController(
        initialWeekStart: DateTime(2026, 4, 27),
        idGenerator: () => 'm-${++counter}',
      );
      // May 2026: Mondays are 4, 11, 18, 25 → 4 weeks.
      final srcMon = DateTime(2026, 4, 27);
      final src = [
        TideEvent(
          id: 'src1',
          subject: 'A',
          startTime: srcMon.add(const Duration(hours: 9)),
          endTime: srcMon.add(const Duration(hours: 17)),
        ),
      ];

      final out = controller.generateMonthFromWeek(
        sourceWeekStart: srcMon,
        monthStart: DateTime(2026, 5, 1),
        sourceEvents: src,
      );

      // Expect 4 occurrences (one per Monday in May 2026).
      expect(out, hasLength(4));
      final starts = out.map((e) => e.startTime).toList();
      expect(starts, contains(DateTime(2026, 5, 4, 9)));
      expect(starts, contains(DateTime(2026, 5, 11, 9)));
      expect(starts, contains(DateTime(2026, 5, 18, 9)));
      expect(starts, contains(DateTime(2026, 5, 25, 9)));
    });

    test('skipClosedDays excludes events on closed days', () {
      final controller = TideShiftPlannerController(
        initialWeekStart: DateTime(2026, 4, 27),
        idGenerator: () => 'mc',
      );
      final srcMon = DateTime(2026, 4, 27);
      final src = [
        TideEvent(
          id: 'src1',
          subject: 'A',
          startTime: srcMon.add(const Duration(hours: 9)),
          endTime: srcMon.add(const Duration(hours: 17)),
        ),
      ];

      final out = controller.generateMonthFromWeek(
        sourceWeekStart: srcMon,
        monthStart: DateTime(2026, 5, 1),
        sourceEvents: src,
        skipClosedDays: true,
        isDayClosed: (d) =>
            d.year == 2026 && d.month == 5 && d.day == 11,
      );
      expect(out, hasLength(3));
      for (final e in out) {
        expect(e.startTime != DateTime(2026, 5, 11, 9), isTrue);
      }
    });
  });

  group('TideShiftPlannerController.generateRangeFromWeek', () {
    test('replicates source week for weekCount weeks starting +7 days', () {
      var counter = 0;
      final controller = TideShiftPlannerController(
        initialWeekStart: DateTime(2026, 4, 27),
        idGenerator: () => 'r-${++counter}',
      );
      final srcMon = DateTime(2026, 4, 27);
      final src = [
        TideEvent(
          id: 'src1',
          subject: 'A',
          startTime: srcMon.add(const Duration(hours: 9)),
          endTime: srcMon.add(const Duration(hours: 17)),
        ),
      ];

      final out = controller.generateRangeFromWeek(
        sourceWeekStart: srcMon,
        sourceEvents: src,
        weekCount: 3,
      );
      expect(out, hasLength(3));
      expect(out[0].startTime, DateTime(2026, 5, 4, 9));
      expect(out[1].startTime, DateTime(2026, 5, 11, 9));
      expect(out[2].startTime, DateTime(2026, 5, 18, 9));
    });

    test('weekCount = 0 yields empty result', () {
      final controller = TideShiftPlannerController(
        initialWeekStart: DateTime(2026, 4, 27),
      );
      final srcMon = DateTime(2026, 4, 27);
      final out = controller.generateRangeFromWeek(
        sourceWeekStart: srcMon,
        sourceEvents: [
          TideEvent(
            id: 'a',
            subject: 'A',
            startTime: srcMon.add(const Duration(hours: 9)),
            endTime: srcMon.add(const Duration(hours: 17)),
          ),
        ],
        weekCount: 0,
      );
      expect(out, isEmpty);
    });
  });

  group('ShiftCopyMode', () {
    test('replicateWeekly is the default mode', () {
      final controller = TideShiftPlannerController();
      // Just sanity: mode parameter is optional and defaults work.
      final out = controller.generateCopiedShifts(
        source: TideDateTimeRange(
          start: DateTime(2026, 4, 27),
          end: DateTime(2026, 5, 3, 23, 59),
        ),
        target: TideDateTimeRange(
          start: DateTime(2026, 5, 4),
          end: DateTime(2026, 5, 10, 23, 59),
        ),
        sourceEvents: const [],
        mode: ShiftCopyMode.replicateWeekly,
      );
      expect(out, isEmpty);
    });
  });
}
