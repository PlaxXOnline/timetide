import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timetide/src/core/models/drag_details.dart';
import 'package:timetide/src/core/models/event.dart';
import 'package:timetide/src/core/models/resource.dart';
import 'package:timetide/src/core/models/template_slot.dart' show TideTimeOfDay;
import 'package:timetide/src/interaction/drag_drop/external_drag.dart';
import 'package:timetide/src/l10n/tide_localizations.dart';
import 'package:timetide/src/widgets/shift_planner/shift_card.dart';
import 'package:timetide/src/widgets/shift_planner/shift_day_column.dart';
import 'package:timetide/src/widgets/shift_planner/shift_drag_mode.dart';
import 'package:timetide/src/widgets/shift_planner/shift_resource_palette.dart';
import 'package:timetide/src/widgets/shift_planner/shift_week_grid.dart';
import 'package:timetide/src/widgets/shift_planner/tide_shift_planner.dart';
import 'package:timetide/src/widgets/shift_planner/tide_shift_planner_controller.dart';

/// Hosts the planner widget with the minimum tree it needs at test time:
/// `Directionality` + `MediaQuery` + `Overlay`. The widget injects its own
/// [TideExternalDragScope] internally, so we do not provide one here.
Widget _host({required Widget child, double width = 1400, double height = 600}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: const MediaQueryData(),
      child: Overlay(
        initialEntries: <OverlayEntry>[
          OverlayEntry(
            builder: (_) => Center(
              child: SizedBox(width: width, height: height, child: child),
            ),
          ),
        ],
      ),
    ),
  );
}

const _alice = TideResource(
  id: 'alice',
  displayName: 'Alice Adams',
  color: Color(0xFF1F7A8C),
);
const _bob = TideResource(
  id: 'bob',
  displayName: 'Bob Brown',
  color: Color(0xFFE63946),
);

const _resources = <TideResource>[_alice, _bob];

/// Simulate a drop landing on the day column for [date] using the shared
/// [TideExternalDragScope] notifier. Returns nothing — caller pumps after.
void _simulateDropOnDay({
  required WidgetTester tester,
  required DateTime date,
  required TideExternalDragData data,
}) {
  // Find the day-column for the given date.
  final dayKey = ValueKey<String>(
    'shift-day-column-${date.year}-${date.month}-${date.day}',
  );
  final columnFinder = find.byKey(dayKey);
  expect(columnFinder, findsOneWidget,
      reason: 'expected to find day column for $date');

  final RenderBox box = tester.renderObject(columnFinder) as RenderBox;
  final center = box.localToGlobal(box.size.center(Offset.zero));

  final BuildContext ctx = tester.element(columnFinder);
  final notifier = TideExternalDragScope.of(ctx);
  expect(notifier, isNotNull,
      reason: 'TideShiftPlanner must inject a TideExternalDragScope');

  notifier!.drop(data, center);
}

/// Builds a payload identical to what ShiftResourcePalette would emit for
/// [resource]. Useful when we want to bypass real pointer events and just
/// exercise the drop handler.
TideExternalDragData _paletteData(TideResource resource,
    {Duration duration = const Duration(hours: 8)}) {
  return TideExternalDragData(
    subject: resource.displayName,
    duration: duration,
    color: resource.color,
    metadata: <String, dynamic>{'resourceId': resource.id},
  );
}

void main() {
  // Monday, 27 April 2026 (ISO weekday 1).
  final monday = DateTime(2026, 4, 27);

  group('TideShiftPlanner — layout', () {
    testWidgets('renders sidebar palette + 7-column grid', (tester) async {
      await tester.pumpWidget(_host(
        child: TideShiftPlanner(
          resources: _resources,
          events: const <TideEvent>[],
          weekStart: monday,
        ),
      ));

      expect(find.byType(ShiftResourcePalette), findsOneWidget);
      expect(find.byType(ShiftWeekGrid), findsOneWidget);
      expect(find.byType(ShiftDayColumn), findsNWidgets(7));
    });

    testWidgets('renders one row per resource in the sidebar',
        (tester) async {
      await tester.pumpWidget(_host(
        child: TideShiftPlanner(
          resources: _resources,
          events: const <TideEvent>[],
          weekStart: monday,
        ),
      ));

      final sources =
          tester.widgetList<TideDragSource>(find.byType(TideDragSource));
      expect(sources, hasLength(2));
      expect(find.text('Alice Adams'), findsOneWidget);
      expect(find.text('Bob Brown'), findsOneWidget);
    });

    testWidgets('renders events in the grid (routed by start day)',
        (tester) async {
      final events = <TideEvent>[
        TideEvent(
          id: 'mon-1',
          subject: 'Alice',
          startTime: DateTime(2026, 4, 27, 9),
          endTime: DateTime(2026, 4, 27, 17),
          resourceIds: const <String>['alice'],
        ),
        TideEvent(
          id: 'wed-1',
          subject: 'Bob',
          startTime: DateTime(2026, 4, 29, 8),
          endTime: DateTime(2026, 4, 29, 16),
          resourceIds: const <String>['bob'],
        ),
      ];

      await tester.pumpWidget(_host(
        child: TideShiftPlanner(
          resources: _resources,
          events: events,
          weekStart: monday,
        ),
      ));

      final cols = tester
          .widgetList<ShiftDayColumn>(find.byType(ShiftDayColumn))
          .toList(growable: false);
      expect(cols.elementAt(0).events.map((e) => e.id), <String>['mon-1']);
      expect(cols.elementAt(2).events.map((e) => e.id), <String>['wed-1']);
    });
  });

  group('TideShiftPlanner — closed day blocks drop', () {
    testWidgets('closedDaysOfWeek={Sunday} → drop on Sunday is dropped silently',
        (tester) async {
      final calls = <TideEvent>[];

      await tester.pumpWidget(_host(
        child: TideShiftPlanner(
          resources: _resources,
          events: const <TideEvent>[],
          weekStart: monday,
          closedDaysOfWeek: const <int>{DateTime.sunday},
          onShiftCreated: calls.add,
        ),
      ));

      // 2026-05-03 is the Sunday of this week; column exists but is closed
      // and therefore not wrapped in a TideDragTarget. Bypassing via the
      // notifier still must not produce an event because the planner
      // re-checks the predicate before dispatching.
      _simulateDropOnDay(
        tester: tester,
        date: DateTime(2026, 5, 3),
        data: _paletteData(_alice),
      );
      await tester.pump();

      expect(calls, isEmpty,
          reason: 'closed Sunday must block onShiftCreated');
    });

    testWidgets('closedDates blocks drop on listed concrete date',
        (tester) async {
      final calls = <TideEvent>[];
      final blockedDate = DateTime(2026, 4, 29); // Wednesday

      await tester.pumpWidget(_host(
        child: TideShiftPlanner(
          resources: _resources,
          events: const <TideEvent>[],
          weekStart: monday,
          closedDates: <DateTime>{blockedDate},
          onShiftCreated: calls.add,
        ),
      ));

      _simulateDropOnDay(
        tester: tester,
        date: blockedDate,
        data: _paletteData(_alice),
      );
      await tester.pump();

      expect(calls, isEmpty);
    });

    testWidgets('isDayClosed predicate blocks drop on matching dates',
        (tester) async {
      final calls = <TideEvent>[];

      await tester.pumpWidget(_host(
        child: TideShiftPlanner(
          resources: _resources,
          events: const <TideEvent>[],
          weekStart: monday,
          // Tuesday (day == 28).
          isDayClosed: (DateTime d) => d.day == 28,
          onShiftCreated: calls.add,
        ),
      ));

      _simulateDropOnDay(
        tester: tester,
        date: DateTime(2026, 4, 28),
        data: _paletteData(_alice),
      );
      await tester.pump();

      expect(calls, isEmpty);
    });
  });

  group('TideShiftPlanner — drag → onShiftCreated', () {
    testWidgets('drop on Monday → onShiftCreated with correct resourceId + date',
        (tester) async {
      TideEvent? created;

      await tester.pumpWidget(_host(
        child: TideShiftPlanner(
          resources: _resources,
          events: const <TideEvent>[],
          weekStart: monday,
          onShiftCreated: (e) => created = e,
        ),
      ));

      _simulateDropOnDay(
        tester: tester,
        date: monday,
        data: _paletteData(_alice),
      );
      await tester.pump();

      expect(created, isNotNull);
      expect(created!.resourceIds, <String>['alice']);
      expect(created!.startTime.year, 2026);
      expect(created!.startTime.month, 4);
      expect(created!.startTime.day, 27);
    });

    testWidgets('instantWithDefaults: builds event with defaultShiftStart/End',
        (tester) async {
      TideEvent? created;

      await tester.pumpWidget(_host(
        child: TideShiftPlanner(
          resources: _resources,
          events: const <TideEvent>[],
          weekStart: monday,
          // dragMode default is instantWithDefaults.
          defaultShiftStart: const TideTimeOfDay(hour: 7, minute: 30),
          defaultShiftEnd: const TideTimeOfDay(hour: 15, minute: 45),
          onShiftCreated: (e) => created = e,
        ),
      ));

      _simulateDropOnDay(
        tester: tester,
        date: monday,
        data: _paletteData(_alice),
      );
      await tester.pump();

      expect(created, isNotNull);
      expect(created!.startTime, DateTime(2026, 4, 27, 7, 30));
      expect(created!.endTime, DateTime(2026, 4, 27, 15, 45));
      expect(created!.color, _alice.color);
    });

    testWidgets(
        'promptForTime: calls builder, awaits Future, fires onShiftCreated '
        'when result is non-null', (tester) async {
      TideEvent? created;
      final completer = Completer<TideEvent?>();
      var builderCalls = 0;

      await tester.pumpWidget(_host(
        child: TideShiftPlanner(
          resources: _resources,
          events: const <TideEvent>[],
          weekStart: monday,
          dragMode: ShiftDragMode.promptForTime,
          shiftPromptBuilder: (ctx, resource, date) {
            builderCalls++;
            expect(resource.id, _alice.id);
            expect(date.day, 27);
            return completer.future;
          },
          onShiftCreated: (e) => created = e,
        ),
      ));

      _simulateDropOnDay(
        tester: tester,
        date: monday,
        data: _paletteData(_alice),
      );
      await tester.pump();
      expect(builderCalls, 1);
      expect(created, isNull, reason: 'must wait for the future');

      final returned = TideEvent(
        id: 'manual-1',
        subject: 'Custom',
        startTime: DateTime(2026, 4, 27, 10),
        endTime: DateTime(2026, 4, 27, 14),
        resourceIds: const <String>['alice'],
      );
      completer.complete(returned);
      await tester.pump();

      expect(created, isNotNull);
      expect(created!.id, 'manual-1');
    });

    testWidgets('promptForTime: null result → no onShiftCreated',
        (tester) async {
      TideEvent? created;

      await tester.pumpWidget(_host(
        child: TideShiftPlanner(
          resources: _resources,
          events: const <TideEvent>[],
          weekStart: monday,
          dragMode: ShiftDragMode.promptForTime,
          shiftPromptBuilder: (ctx, resource, date) async => null,
          onShiftCreated: (e) => created = e,
        ),
      ));

      _simulateDropOnDay(
        tester: tester,
        date: monday,
        data: _paletteData(_alice),
      );
      await tester.pump();
      // Allow any micro-tasks from the async prompt builder to settle.
      await tester.pumpAndSettle();

      expect(created, isNull);
    });
  });

  group('TideShiftPlanner — tap & add', () {
    testWidgets('tap on a shift card → onShiftTap with the event',
        (tester) async {
      TideEvent? tapped;
      final shift = TideEvent(
        id: 's-1',
        subject: 'Alice',
        startTime: DateTime(2026, 4, 27, 9),
        endTime: DateTime(2026, 4, 27, 17),
        resourceIds: const <String>['alice'],
      );

      await tester.pumpWidget(_host(
        child: TideShiftPlanner(
          resources: _resources,
          events: <TideEvent>[shift],
          weekStart: monday,
          onShiftTap: (e) => tapped = e,
        ),
      ));

      await tester.tap(find.byKey(const ValueKey('shift-card-container')));
      await tester.pump();

      expect(tapped, isNotNull);
      expect(tapped!.id, 's-1');
    });

    testWidgets('+ Schicht button → onAddShiftPressed with the column date',
        (tester) async {
      DateTime? addedFor;

      await tester.pumpWidget(_host(
        child: TideShiftPlanner(
          resources: _resources,
          events: const <TideEvent>[],
          weekStart: monday,
          onAddShiftPressed: (d) => addedFor = d,
        ),
      ));

      // Tap the very first add-shift button (Monday column).
      await tester.tap(
        find.byKey(const ValueKey<String>('add-shift-button')).first,
      );
      await tester.pump();

      expect(addedFor, isNotNull);
      expect(addedFor!.year, 2026);
      expect(addedFor!.month, 4);
      expect(addedFor!.day, 27);
    });
  });

  group('TideShiftPlanner — controller integration', () {
    testWidgets('controller change triggers a rebuild with new week',
        (tester) async {
      final controller = TideShiftPlannerController(
        initialWeekStart: monday,
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(_host(
        child: TideShiftPlanner(
          resources: _resources,
          events: const <TideEvent>[],
          // Provide some weekStart — controller must override it.
          weekStart: DateTime(2000, 1, 3),
          controller: controller,
        ),
      ));

      // Initial render: Monday 27 April.
      expect(find.text('27'), findsOneWidget);

      controller.goToNextWeek();
      await tester.pump();

      // Now Monday 4 May 2026 → first day shows '4'.
      expect(find.text('4'), findsOneWidget);
      expect(find.text('27'), findsNothing);
    });

    testWidgets(
        'controller.currentWeekStart overrides widget.weekStart when set',
        (tester) async {
      final controller = TideShiftPlannerController(
        initialWeekStart: DateTime(2026, 5, 4), // Monday
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(_host(
        child: TideShiftPlanner(
          resources: _resources,
          events: const <TideEvent>[],
          weekStart: monday, // would otherwise be 27 April
          controller: controller,
        ),
      ));

      final cols = tester
          .widgetList<ShiftDayColumn>(find.byType(ShiftDayColumn))
          .toList(growable: false);
      expect(cols.first.date, DateTime(2026, 5, 4));
    });
  });

  group('TideShiftPlanner — cardBuilder', () {
    testWidgets('uses cardBuilder when provided instead of default ShiftCard',
        (tester) async {
      final shift = TideEvent(
        id: 'mon-1',
        subject: 'Alice',
        startTime: DateTime(2026, 4, 27, 9),
        endTime: DateTime(2026, 4, 27, 17),
        resourceIds: const <String>['alice'],
      );

      await tester.pumpWidget(_host(
        child: TideShiftPlanner(
          resources: _resources,
          events: <TideEvent>[shift],
          weekStart: monday,
          cardBuilder: (ctx, event, resource) => Text('CUSTOM-${event.id}'),
        ),
      ));

      expect(find.text('CUSTOM-mon-1'), findsOneWidget);
      expect(find.byType(ShiftCard), findsNothing,
          reason: 'default ShiftCard must not be used when cardBuilder is set');
    });

    testWidgets('passes correct event + resource to cardBuilder',
        (tester) async {
      final events = <TideEvent>[
        TideEvent(
          id: 'mon-1',
          subject: 'Alice',
          startTime: DateTime(2026, 4, 27, 9),
          endTime: DateTime(2026, 4, 27, 17),
          resourceIds: const <String>['alice'],
        ),
        TideEvent(
          id: 'wed-1',
          subject: 'Bob',
          startTime: DateTime(2026, 4, 29, 8),
          endTime: DateTime(2026, 4, 29, 16),
          resourceIds: const <String>['bob'],
        ),
      ];

      final captured = <(String, String)>[];

      await tester.pumpWidget(_host(
        child: TideShiftPlanner(
          resources: _resources,
          events: events,
          weekStart: monday,
          cardBuilder: (ctx, event, resource) {
            captured.add((event.id, resource.id));
            return Text('CB-${event.id}-${resource.id}');
          },
        ),
      ));

      expect(captured, contains(('mon-1', 'alice')));
      expect(captured, contains(('wed-1', 'bob')));
      expect(find.text('CB-mon-1-alice'), findsOneWidget);
      expect(find.text('CB-wed-1-bob'), findsOneWidget);
    });

    testWidgets('falls back to default ShiftCard when cardBuilder is null',
        (tester) async {
      final shift = TideEvent(
        id: 'mon-1',
        subject: 'Alice',
        startTime: DateTime(2026, 4, 27, 9),
        endTime: DateTime(2026, 4, 27, 17),
        resourceIds: const <String>['alice'],
      );

      await tester.pumpWidget(_host(
        child: TideShiftPlanner(
          resources: _resources,
          events: <TideEvent>[shift],
          weekStart: monday,
          // cardBuilder omitted on purpose.
        ),
      ));

      expect(find.byType(ShiftCard), findsOneWidget);
    });

    testWidgets('cardBuilder is not invoked for events with missing resource',
        (tester) async {
      final shift = TideEvent(
        id: 'orphan-1',
        subject: 'Orphan',
        startTime: DateTime(2026, 4, 27, 9),
        endTime: DateTime(2026, 4, 27, 17),
        resourceIds: const <String>['ghost'], // not in _resources
      );
      var calls = 0;

      await tester.pumpWidget(_host(
        child: TideShiftPlanner(
          resources: _resources,
          events: <TideEvent>[shift],
          weekStart: monday,
          cardBuilder: (ctx, event, resource) {
            calls++;
            return Text('CB-${event.id}');
          },
        ),
      ));

      expect(calls, 0,
          reason: 'cardBuilder must be skipped when resource cannot be resolved');
      expect(find.text('CB-orphan-1'), findsNothing);
    });
  });

  group('TideShiftPlanner — onShiftUpdated via shiftEditPromptBuilder', () {
    testWidgets(
        'tap fires editPromptBuilder, onShiftUpdated called with non-null '
        'result', (tester) async {
      TideEvent? updated;
      final shift = TideEvent(
        id: 's-1',
        subject: 'Alice',
        startTime: DateTime(2026, 4, 27, 9),
        endTime: DateTime(2026, 4, 27, 17),
        resourceIds: const <String>['alice'],
      );
      final edited = TideEvent(
        id: 's-1',
        subject: 'Alice (edited)',
        startTime: DateTime(2026, 4, 27, 10),
        endTime: DateTime(2026, 4, 27, 18),
        resourceIds: const <String>['alice'],
      );

      await tester.pumpWidget(_host(
        child: TideShiftPlanner(
          resources: _resources,
          events: <TideEvent>[shift],
          weekStart: monday,
          shiftEditPromptBuilder: (ctx, event, resource) async => edited,
          onShiftUpdated: (e) => updated = e,
        ),
      ));

      await tester.tap(find.byKey(const ValueKey('shift-card-container')));
      await tester.pumpAndSettle();

      expect(updated, isNotNull);
      expect(updated!.subject, 'Alice (edited)');
      expect(updated!.startTime, DateTime(2026, 4, 27, 10));
    });

    testWidgets('tap fires editPromptBuilder, null result -> no onShiftUpdated',
        (tester) async {
      TideEvent? updated;
      final shift = TideEvent(
        id: 's-1',
        subject: 'Alice',
        startTime: DateTime(2026, 4, 27, 9),
        endTime: DateTime(2026, 4, 27, 17),
        resourceIds: const <String>['alice'],
      );

      await tester.pumpWidget(_host(
        child: TideShiftPlanner(
          resources: _resources,
          events: <TideEvent>[shift],
          weekStart: monday,
          shiftEditPromptBuilder: (ctx, event, resource) async => null,
          onShiftUpdated: (e) => updated = e,
        ),
      ));

      await tester.tap(find.byKey(const ValueKey('shift-card-container')));
      await tester.pumpAndSettle();

      expect(updated, isNull,
          reason: 'null result must not trigger onShiftUpdated');
    });

    testWidgets(
        'editPromptBuilder set: onShiftTap is NOT called (editPromptBuilder '
        'wins)', (tester) async {
      TideEvent? tapped;
      TideEvent? updated;
      final shift = TideEvent(
        id: 's-1',
        subject: 'Alice',
        startTime: DateTime(2026, 4, 27, 9),
        endTime: DateTime(2026, 4, 27, 17),
        resourceIds: const <String>['alice'],
      );

      await tester.pumpWidget(_host(
        child: TideShiftPlanner(
          resources: _resources,
          events: <TideEvent>[shift],
          weekStart: monday,
          shiftEditPromptBuilder: (ctx, event, resource) async => event,
          onShiftTap: (e) => tapped = e,
          onShiftUpdated: (e) => updated = e,
        ),
      ));

      await tester.tap(find.byKey(const ValueKey('shift-card-container')));
      await tester.pumpAndSettle();

      expect(tapped, isNull,
          reason: 'onShiftTap must NOT be called when editPromptBuilder set');
      expect(updated, isNotNull);
    });

    testWidgets('only onShiftTap set: tap fires onShiftTap (legacy path)',
        (tester) async {
      TideEvent? tapped;
      final shift = TideEvent(
        id: 's-1',
        subject: 'Alice',
        startTime: DateTime(2026, 4, 27, 9),
        endTime: DateTime(2026, 4, 27, 17),
        resourceIds: const <String>['alice'],
      );

      await tester.pumpWidget(_host(
        child: TideShiftPlanner(
          resources: _resources,
          events: <TideEvent>[shift],
          weekStart: monday,
          // shiftEditPromptBuilder omitted on purpose.
          onShiftTap: (e) => tapped = e,
        ),
      ));

      await tester.tap(find.byKey(const ValueKey('shift-card-container')));
      await tester.pump();

      expect(tapped, isNotNull);
      expect(tapped!.id, 's-1');
    });

    testWidgets('editPromptBuilder receives correct event + resource',
        (tester) async {
      TideEvent? capturedEvent;
      TideResource? capturedResource;
      final shift = TideEvent(
        id: 'mon-bob',
        subject: 'Bob',
        startTime: DateTime(2026, 4, 27, 9),
        endTime: DateTime(2026, 4, 27, 17),
        resourceIds: const <String>['bob'],
      );

      await tester.pumpWidget(_host(
        child: TideShiftPlanner(
          resources: _resources,
          events: <TideEvent>[shift],
          weekStart: monday,
          shiftEditPromptBuilder: (ctx, event, resource) async {
            capturedEvent = event;
            capturedResource = resource;
            return null;
          },
        ),
      ));

      await tester.tap(find.byKey(const ValueKey('shift-card-container')));
      await tester.pumpAndSettle();

      expect(capturedEvent, isNotNull);
      expect(capturedEvent!.id, 'mon-bob');
      expect(capturedResource, isNotNull);
      expect(capturedResource!.id, 'bob');
    });

    testWidgets(
        'event with missing resource -> editPromptBuilder NOT called (silent '
        'skip)', (tester) async {
      var builderCalls = 0;
      TideEvent? updated;
      // Event with empty resourceIds: the day-column never builds a card
      // for it (it has no routing key) and the planner-level silent-skip
      // guard never gets reached via UI. This test still asserts the
      // safety property end-to-end: such events do not produce updates.
      final orphan = TideEvent(
        id: 'orphan',
        subject: 'Orphan',
        startTime: DateTime(2026, 4, 27, 9),
        endTime: DateTime(2026, 4, 27, 17),
        resourceIds: const <String>[],
      );

      await tester.pumpWidget(_host(
        child: TideShiftPlanner(
          resources: _resources,
          events: <TideEvent>[orphan],
          weekStart: monday,
          shiftEditPromptBuilder: (ctx, event, resource) async {
            builderCalls++;
            return event;
          },
          onShiftUpdated: (e) => updated = e,
        ),
      ));
      await tester.pump();

      expect(builderCalls, 0,
          reason: 'editPromptBuilder must not fire for unresolvable events');
      expect(updated, isNull);
      // No card rendered for an event whose resource cannot be resolved.
      expect(find.byKey(const ValueKey('shift-card-container')), findsNothing);
    });
  });

  group('TideShiftPlanner — localization', () {
    testWidgets('localeOverride is used when provided', (tester) async {
      await tester.pumpWidget(_host(
        child: TideShiftPlanner(
          resources: _resources,
          events: const <TideEvent>[],
          weekStart: monday,
          localeOverride: TideLocalizations.de(),
        ),
      ));

      // German weekday abbreviations come from TideLocalizations.de().
      expect(find.text('Mo'), findsOneWidget);
      expect(find.text('Di'), findsOneWidget);
      // German add-shift button label.
      expect(find.text('+ Schicht'), findsWidgets);
    });

    testWidgets('default locale fallback works without Localizations '
        'in the tree', (tester) async {
      await tester.pumpWidget(_host(
        child: TideShiftPlanner(
          resources: _resources,
          events: const <TideEvent>[],
          weekStart: monday,
        ),
      ));

      // English fallback labels.
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Sun'), findsOneWidget);
      expect(find.text('+ Shift'), findsWidgets);
    });
  });
}
