import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timetide/src/core/models/drag_details.dart';
import 'package:timetide/src/core/models/event.dart';
import 'package:timetide/src/core/models/resource.dart';
import 'package:timetide/src/interaction/drag_drop/external_drag.dart';
import 'package:timetide/src/l10n/tide_localizations.dart';
import 'package:timetide/src/theme/tide_theme.dart';
import 'package:timetide/src/theme/tide_theme_data.dart';
import 'package:timetide/src/widgets/shift_planner/shift_day_column.dart';
import 'package:timetide/src/widgets/shift_planner/shift_week_grid.dart';

/// Wraps the grid in the minimum tree it needs at test time:
/// `Directionality` + `MediaQuery` + `Overlay` + `TideExternalDragScope`,
/// plus an optional `TideTheme`. The grid is given an explicit size so its
/// `Expanded` body has bounded height in tests.
Widget _host({required Widget child, TideThemeData? theme}) {
  Widget tree = TideExternalDragScope(
    child: SizedBox(width: 1400, height: 600, child: child),
  );
  if (theme != null) {
    tree = TideTheme(data: theme, child: tree);
  }
  return Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: const MediaQueryData(),
      child: Overlay(
        initialEntries: <OverlayEntry>[
          OverlayEntry(builder: (_) => Center(child: tree)),
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

const _resourceMap = <String, TideResource>{
  'alice': _alice,
  'bob': _bob,
};

TideEvent _shift({
  required String id,
  required String resourceId,
  required DateTime start,
  required DateTime end,
  String subject = 'Shift',
}) {
  return TideEvent(
    id: id,
    subject: subject,
    startTime: start,
    endTime: end,
    resourceIds: <String>[resourceId],
  );
}

void main() {
  // Monday, 23 March 2026 (ISO weekday 1).
  final monday = DateTime(2026, 3, 23);

  group('ShiftWeekGrid — column count and date mapping', () {
    testWidgets('renders 7 ShiftDayColumn widgets', (tester) async {
      await tester.pumpWidget(_host(
        child: ShiftWeekGrid(
          weekStart: monday,
          events: const <TideEvent>[],
          resourceById: _resourceMap,
        ),
      ));

      expect(find.byType(ShiftDayColumn), findsNWidgets(7));
    });

    testWidgets('column dates are weekStart + 0..6 days in order',
        (tester) async {
      await tester.pumpWidget(_host(
        child: ShiftWeekGrid(
          weekStart: monday,
          events: const <TideEvent>[],
          resourceById: _resourceMap,
        ),
      ));

      final cols = tester
          .widgetList<ShiftDayColumn>(find.byType(ShiftDayColumn))
          .toList(growable: false);
      expect(cols.map((c) => c.date.day).toList(),
          <int>[23, 24, 25, 26, 27, 28, 29]);
      // All in March 2026.
      for (final c in cols) {
        expect(c.date.year, 2026);
        expect(c.date.month, 3);
      }
    });
  });

  group('ShiftWeekGrid — header row', () {
    testWidgets('header container is keyed and contains 7 day numbers',
        (tester) async {
      await tester.pumpWidget(_host(
        child: ShiftWeekGrid(
          weekStart: monday,
          events: const <TideEvent>[],
          resourceById: _resourceMap,
        ),
      ));

      expect(find.byKey(const ValueKey('shift-week-grid-header')),
          findsOneWidget);

      // Each weekday number should appear in the header.
      for (final day in <int>[23, 24, 25, 26, 27, 28, 29]) {
        expect(find.text('$day'), findsOneWidget);
      }
    });

    testWidgets('header renders weekday labels (English fallback)',
        (tester) async {
      await tester.pumpWidget(_host(
        child: ShiftWeekGrid(
          weekStart: monday,
          events: const <TideEvent>[],
          resourceById: _resourceMap,
        ),
      ));

      // English short weekday names from TideLocalizations.en().
      for (final label in <String>[
        'Mon',
        'Tue',
        'Wed',
        'Thu',
        'Fri',
        'Sat',
        'Sun',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets('header weekday labels respect locale override (DE)',
        (tester) async {
      await tester.pumpWidget(_host(
        child: ShiftWeekGrid(
          weekStart: monday,
          events: const <TideEvent>[],
          resourceById: _resourceMap,
          locale: TideLocalizations.de(),
        ),
      ));

      for (final label in <String>[
        'Mo',
        'Di',
        'Mi',
        'Do',
        'Fr',
        'Sa',
        'So',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
    });
  });

  group('ShiftWeekGrid — closed-day routing', () {
    testWidgets('closedDaysOfWeek={Sunday} marks only the 7th column closed',
        (tester) async {
      await tester.pumpWidget(_host(
        child: ShiftWeekGrid(
          weekStart: monday,
          events: const <TideEvent>[],
          resourceById: _resourceMap,
          closedDaysOfWeek: const <int>{DateTime.sunday},
        ),
      ));

      final cols = tester
          .widgetList<ShiftDayColumn>(find.byType(ShiftDayColumn))
          .toList(growable: false);
      expect(cols, hasLength(7));
      expect(cols.elementAt(6).closed, isTrue);
      for (var i = 0; i < 6; i++) {
        expect(cols.elementAt(i).closed, isFalse,
            reason: 'column $i should be open');
      }
    });

    testWidgets('closedDates routing — Wednesday 2026-03-25 is closed',
        (tester) async {
      await tester.pumpWidget(_host(
        child: ShiftWeekGrid(
          weekStart: monday,
          events: const <TideEvent>[],
          resourceById: _resourceMap,
          closedDates: <DateTime>{DateTime(2026, 3, 25)},
        ),
      ));

      final cols = tester
          .widgetList<ShiftDayColumn>(find.byType(ShiftDayColumn))
          .toList(growable: false);
      // Wednesday is index 2 (Mon=0, Tue=1, Wed=2).
      expect(cols.elementAt(2).closed, isTrue);
      // Others are open.
      for (var i = 0; i < 7; i++) {
        if (i == 2) continue;
        expect(cols.elementAt(i).closed, isFalse,
            reason: 'column $i should be open');
      }
    });

    testWidgets('custom isDayClosed predicate — only Tuesday (day == 24)',
        (tester) async {
      await tester.pumpWidget(_host(
        child: ShiftWeekGrid(
          weekStart: monday,
          events: const <TideEvent>[],
          resourceById: _resourceMap,
          isDayClosed: (DateTime d) => d.day == 24,
        ),
      ));

      final cols = tester
          .widgetList<ShiftDayColumn>(find.byType(ShiftDayColumn))
          .toList(growable: false);
      expect(cols.elementAt(1).closed, isTrue);
      for (var i = 0; i < 7; i++) {
        if (i == 1) continue;
        expect(cols.elementAt(i).closed, isFalse,
            reason: 'column $i should be open');
      }
    });

    testWidgets(
        'combined OR logic — closedDaysOfWeek + closedDates + predicate',
        (tester) async {
      // Sunday (index 6), Wednesday (index 2 via dates), Tuesday (index 1
      // via predicate) — all should be closed simultaneously.
      await tester.pumpWidget(_host(
        child: ShiftWeekGrid(
          weekStart: monday,
          events: const <TideEvent>[],
          resourceById: _resourceMap,
          closedDaysOfWeek: const <int>{DateTime.sunday},
          closedDates: <DateTime>{DateTime(2026, 3, 25)},
          isDayClosed: (DateTime d) => d.day == 24,
        ),
      ));

      final cols = tester
          .widgetList<ShiftDayColumn>(find.byType(ShiftDayColumn))
          .toList(growable: false);
      // Closed: indices 1 (Tue), 2 (Wed), 6 (Sun).
      expect(cols.elementAt(1).closed, isTrue);
      expect(cols.elementAt(2).closed, isTrue);
      expect(cols.elementAt(6).closed, isTrue);
      // Open: indices 0 (Mon), 3 (Thu), 4 (Fri), 5 (Sat).
      for (final i in <int>[0, 3, 4, 5]) {
        expect(cols.elementAt(i).closed, isFalse,
            reason: 'column $i should be open');
      }
    });
  });

  group('ShiftWeekGrid — events routing', () {
    testWidgets('events are filtered per column by startTime date',
        (tester) async {
      // Mon: 2 events, Wed: 1 event, others: 0.
      final events = <TideEvent>[
        _shift(
          id: 'mon-1',
          resourceId: 'alice',
          start: DateTime(2026, 3, 23, 9),
          end: DateTime(2026, 3, 23, 12),
        ),
        _shift(
          id: 'mon-2',
          resourceId: 'bob',
          start: DateTime(2026, 3, 23, 14),
          end: DateTime(2026, 3, 23, 18),
        ),
        _shift(
          id: 'wed-1',
          resourceId: 'alice',
          start: DateTime(2026, 3, 25, 8),
          end: DateTime(2026, 3, 25, 16),
        ),
      ];

      await tester.pumpWidget(_host(
        child: ShiftWeekGrid(
          weekStart: monday,
          events: events,
          resourceById: _resourceMap,
        ),
      ));

      final cols = tester
          .widgetList<ShiftDayColumn>(find.byType(ShiftDayColumn))
          .toList(growable: false);
      expect(cols.elementAt(0).events, hasLength(2));
      expect(cols.elementAt(1).events, isEmpty);
      expect(cols.elementAt(2).events, hasLength(1));
      expect(cols.elementAt(2).events.single.id, 'wed-1');
      for (final i in <int>[3, 4, 5, 6]) {
        expect(cols.elementAt(i).events, isEmpty);
      }
    });

    testWidgets(
        'multi-day events are placed in the start-day column only (no split)',
        (tester) async {
      // Spans Mon → Tue. Should appear only in Monday column.
      final events = <TideEvent>[
        _shift(
          id: 'multi',
          resourceId: 'alice',
          start: DateTime(2026, 3, 23, 22),
          end: DateTime(2026, 3, 24, 6),
        ),
      ];

      await tester.pumpWidget(_host(
        child: ShiftWeekGrid(
          weekStart: monday,
          events: events,
          resourceById: _resourceMap,
        ),
      ));

      final cols = tester
          .widgetList<ShiftDayColumn>(find.byType(ShiftDayColumn))
          .toList(growable: false);
      expect(cols.elementAt(0).events, hasLength(1));
      expect(cols.elementAt(0).events.single.id, 'multi');
      expect(cols.elementAt(1).events, isEmpty);
    });
  });

  group('ShiftWeekGrid — dropTime defaulting', () {
    testWidgets('dropTime defaults to date with hour=9 (default)',
        (tester) async {
      await tester.pumpWidget(_host(
        child: ShiftWeekGrid(
          weekStart: monday,
          events: const <TideEvent>[],
          resourceById: _resourceMap,
        ),
      ));

      final col0 = tester
          .widgetList<ShiftDayColumn>(find.byType(ShiftDayColumn))
          .elementAt(0);
      expect(col0.dropTime, equals(DateTime(2026, 3, 23, 9, 0)));
    });

    testWidgets('defaultDropHour override is honored across all columns',
        (tester) async {
      await tester.pumpWidget(_host(
        child: ShiftWeekGrid(
          weekStart: monday,
          events: const <TideEvent>[],
          resourceById: _resourceMap,
          defaultDropHour: 14,
        ),
      ));

      final cols = tester
          .widgetList<ShiftDayColumn>(find.byType(ShiftDayColumn))
          .toList(growable: false);
      for (var i = 0; i < 7; i++) {
        expect(cols.elementAt(i).dropTime,
            equals(DateTime(2026, 3, 23 + i, 14, 0)));
      }
    });
  });

  group('ShiftWeekGrid — callbacks pass-through', () {
    testWidgets('forwards onShiftTap, onAddShiftPressed, onExternalDragEnd '
        'unchanged', (tester) async {
      void onTap(TideEvent e) {}
      void onAdd(DateTime d) {}
      void onDrop(TideExternalDragEndDetails d) {}

      await tester.pumpWidget(_host(
        child: ShiftWeekGrid(
          weekStart: monday,
          events: const <TideEvent>[],
          resourceById: _resourceMap,
          onShiftTap: onTap,
          onAddShiftPressed: onAdd,
          onExternalDragEnd: onDrop,
        ),
      ));

      final cols = tester
          .widgetList<ShiftDayColumn>(find.byType(ShiftDayColumn))
          .toList(growable: false);
      for (final c in cols) {
        expect(identical(c.onShiftTap, onTap), isTrue);
        expect(identical(c.onAddShiftPressed, onAdd), isTrue);
        expect(identical(c.onExternalDragEnd, onDrop), isTrue);
      }
    });
  });

  group('ShiftWeekGrid — weekStart normalization', () {
    testWidgets('non-Monday weekStart normalizes back to the previous Monday',
        (tester) async {
      // 2026-03-25 is a Wednesday. Expect first column = 2026-03-23 (Mon).
      await tester.pumpWidget(_host(
        child: ShiftWeekGrid(
          weekStart: DateTime(2026, 3, 25),
          events: const <TideEvent>[],
          resourceById: _resourceMap,
        ),
      ));

      final cols = tester
          .widgetList<ShiftDayColumn>(find.byType(ShiftDayColumn))
          .toList(growable: false);
      expect(cols.elementAt(0).date, equals(DateTime(2026, 3, 23)));
      expect(cols.map((c) => c.date.day).toList(),
          <int>[23, 24, 25, 26, 27, 28, 29]);
    });

    testWidgets('Sunday weekStart normalizes back six days to Monday',
        (tester) async {
      // 2026-03-29 is a Sunday. Previous Monday is 2026-03-23.
      await tester.pumpWidget(_host(
        child: ShiftWeekGrid(
          weekStart: DateTime(2026, 3, 29),
          events: const <TideEvent>[],
          resourceById: _resourceMap,
        ),
      ));

      final cols = tester
          .widgetList<ShiftDayColumn>(find.byType(ShiftDayColumn))
          .toList(growable: false);
      expect(cols.elementAt(0).date, equals(DateTime(2026, 3, 23)));
    });
  });
}
