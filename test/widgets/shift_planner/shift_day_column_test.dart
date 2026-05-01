import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timetide/src/core/models/drag_details.dart';
import 'package:timetide/src/core/models/event.dart';
import 'package:timetide/src/core/models/resource.dart';
import 'package:timetide/src/interaction/drag_drop/external_drag.dart';
import 'package:timetide/src/l10n/tide_localizations.dart';
import 'package:timetide/src/theme/tide_theme.dart';
import 'package:timetide/src/theme/tide_theme_data.dart';
import 'package:timetide/src/widgets/shift_planner/shift_card.dart';
import 'package:timetide/src/widgets/shift_planner/shift_day_column.dart';

/// Wraps the column in the minimum tree it needs at test time:
/// `Directionality` + `MediaQuery` + `TideExternalDragScope`, plus an optional
/// `TideTheme`.
Widget _host({required Widget child, TideThemeData? theme}) {
  Widget tree = TideExternalDragScope(child: child);
  if (theme != null) {
    tree = TideTheme(data: theme, child: tree);
  }
  return Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: const MediaQueryData(),
      child: Overlay(
        initialEntries: <OverlayEntry>[
          OverlayEntry(builder: (_) => tree),
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
  final date = DateTime(2026, 4, 30);
  final dropTime = DateTime(2026, 4, 30, 9);

  group('ShiftDayColumn — closed day', () {
    testWidgets('renders the localized "Closed" label centered',
        (tester) async {
      await tester.pumpWidget(_host(
        child: ShiftDayColumn(
          date: date,
          closed: true,
          events: const <TideEvent>[],
          resourceById: _resourceMap,
          dropTime: dropTime,
        ),
      ));

      expect(find.byKey(const ValueKey('closed-label')), findsOneWidget);
      expect(find.text('Closed'), findsOneWidget);
    });

    testWidgets('respects locale override (DE → "Geschlossen")',
        (tester) async {
      await tester.pumpWidget(_host(
        child: ShiftDayColumn(
          date: date,
          closed: true,
          events: const <TideEvent>[],
          resourceById: _resourceMap,
          dropTime: dropTime,
          locale: TideLocalizations.de(),
        ),
      ));

      expect(find.text('Geschlossen'), findsOneWidget);
    });

    testWidgets('renders no ShiftCard widgets', (tester) async {
      final events = <TideEvent>[
        _shift(
          id: '1',
          resourceId: 'alice',
          start: DateTime(2026, 4, 30, 9),
          end: DateTime(2026, 4, 30, 17),
        ),
      ];
      await tester.pumpWidget(_host(
        child: ShiftDayColumn(
          date: date,
          closed: true,
          events: events,
          resourceById: _resourceMap,
          dropTime: dropTime,
        ),
      ));

      expect(find.byType(ShiftCard), findsNothing);
    });

    testWidgets('does not render the "+ Shift" button', (tester) async {
      await tester.pumpWidget(_host(
        child: ShiftDayColumn(
          date: date,
          closed: true,
          events: const <TideEvent>[],
          resourceById: _resourceMap,
          dropTime: dropTime,
        ),
      ));

      expect(find.byKey(const ValueKey('add-shift-button')), findsNothing);
    });

    testWidgets('does not wrap in TideDragTarget (no drop accepted)',
        (tester) async {
      await tester.pumpWidget(_host(
        child: ShiftDayColumn(
          date: date,
          closed: true,
          events: const <TideEvent>[],
          resourceById: _resourceMap,
          dropTime: dropTime,
        ),
      ));

      expect(find.byType(TideDragTarget), findsNothing);
    });
  });

  group('ShiftDayColumn — open day', () {
    testWidgets('renders one ShiftCard per event', (tester) async {
      final events = <TideEvent>[
        _shift(
          id: '1',
          resourceId: 'alice',
          start: DateTime(2026, 4, 30, 9),
          end: DateTime(2026, 4, 30, 13),
        ),
        _shift(
          id: '2',
          resourceId: 'bob',
          start: DateTime(2026, 4, 30, 14),
          end: DateTime(2026, 4, 30, 18),
        ),
      ];

      await tester.pumpWidget(_host(
        child: ShiftDayColumn(
          date: date,
          closed: false,
          events: events,
          resourceById: _resourceMap,
          dropTime: dropTime,
        ),
      ));

      expect(find.byType(ShiftCard), findsNWidgets(2));
    });

    testWidgets('renders "+ Shift" button at the bottom', (tester) async {
      await tester.pumpWidget(_host(
        child: ShiftDayColumn(
          date: date,
          closed: false,
          events: const <TideEvent>[],
          resourceById: _resourceMap,
          dropTime: dropTime,
        ),
      ));

      expect(find.byKey(const ValueKey('add-shift-button')), findsOneWidget);
      expect(find.text('+ Shift'), findsOneWidget);
    });

    testWidgets('"+ Shift" label uses locale override (DE → "+ Schicht")',
        (tester) async {
      await tester.pumpWidget(_host(
        child: ShiftDayColumn(
          date: date,
          closed: false,
          events: const <TideEvent>[],
          resourceById: _resourceMap,
          dropTime: dropTime,
          locale: TideLocalizations.de(),
        ),
      ));

      expect(find.text('+ Schicht'), findsOneWidget);
    });

    testWidgets('is wrapped in a TideDragTarget', (tester) async {
      await tester.pumpWidget(_host(
        child: ShiftDayColumn(
          date: date,
          closed: false,
          events: const <TideEvent>[],
          resourceById: _resourceMap,
          dropTime: dropTime,
        ),
      ));

      expect(find.byType(TideDragTarget), findsOneWidget);
    });
  });

  group('ShiftDayColumn — sort order', () {
    testWidgets('events passed in unsorted are rendered ascending by startTime',
        (tester) async {
      // Deliberately unsorted: late, early, middle.
      final events = <TideEvent>[
        _shift(
          id: 'late',
          resourceId: 'alice',
          start: DateTime(2026, 4, 30, 18),
          end: DateTime(2026, 4, 30, 20),
        ),
        _shift(
          id: 'early',
          resourceId: 'alice',
          start: DateTime(2026, 4, 30, 6),
          end: DateTime(2026, 4, 30, 9),
        ),
        _shift(
          id: 'mid',
          resourceId: 'bob',
          start: DateTime(2026, 4, 30, 12),
          end: DateTime(2026, 4, 30, 15),
        ),
      ];

      await tester.pumpWidget(_host(
        child: ShiftDayColumn(
          date: date,
          closed: false,
          events: events,
          resourceById: _resourceMap,
          dropTime: dropTime,
        ),
      ));

      final cards = tester
          .widgetList<ShiftCard>(find.byType(ShiftCard))
          .toList(growable: false);
      expect(cards, hasLength(3));

      final times = cards.map((c) => c.event.startTime).toList();
      expect(times[0].isBefore(times[1]), isTrue);
      expect(times[1].isBefore(times[2]), isTrue);
      expect(cards[0].event.id, 'early');
      expect(cards[1].event.id, 'mid');
      expect(cards[2].event.id, 'late');
    });
  });

  group('ShiftDayColumn — resource lookup', () {
    testWidgets('skips events whose resourceId is missing from the map',
        (tester) async {
      final events = <TideEvent>[
        _shift(
          id: 'known',
          resourceId: 'alice',
          start: DateTime(2026, 4, 30, 9),
          end: DateTime(2026, 4, 30, 13),
        ),
        _shift(
          id: 'unknown',
          resourceId: 'ghost',
          start: DateTime(2026, 4, 30, 14),
          end: DateTime(2026, 4, 30, 18),
        ),
      ];

      await tester.pumpWidget(_host(
        child: ShiftDayColumn(
          date: date,
          closed: false,
          events: events,
          resourceById: _resourceMap,
          dropTime: dropTime,
        ),
      ));

      expect(tester.takeException(), isNull);
      // Only the known event renders a card.
      expect(find.byType(ShiftCard), findsOneWidget);
      final card = tester.widget<ShiftCard>(find.byType(ShiftCard));
      expect(card.event.id, 'known');
    });

    testWidgets('skips events with null/empty resourceIds without crashing',
        (tester) async {
      final events = <TideEvent>[
        TideEvent(
          id: 'no-resource',
          subject: 'Lonely',
          startTime: DateTime(2026, 4, 30, 9),
          endTime: DateTime(2026, 4, 30, 13),
        ),
      ];

      await tester.pumpWidget(_host(
        child: ShiftDayColumn(
          date: date,
          closed: false,
          events: events,
          resourceById: _resourceMap,
          dropTime: dropTime,
        ),
      ));

      expect(tester.takeException(), isNull);
      expect(find.byType(ShiftCard), findsNothing);
    });
  });

  group('ShiftDayColumn — callbacks', () {
    testWidgets('tapping "+ Shift" invokes onAddShiftPressed with the date',
        (tester) async {
      final invocations = <DateTime>[];

      await tester.pumpWidget(_host(
        child: ShiftDayColumn(
          date: date,
          closed: false,
          events: const <TideEvent>[],
          resourceById: _resourceMap,
          dropTime: dropTime,
          onAddShiftPressed: invocations.add,
        ),
      ));

      await tester.tap(find.byKey(const ValueKey('add-shift-button')));
      await tester.pump();

      expect(invocations, hasLength(1));
      expect(invocations.single, equals(date));
    });

    testWidgets('tapping a ShiftCard invokes onShiftTap with the event',
        (tester) async {
      final tapped = <TideEvent>[];
      final event = _shift(
        id: 's1',
        resourceId: 'alice',
        start: DateTime(2026, 4, 30, 9),
        end: DateTime(2026, 4, 30, 13),
      );

      await tester.pumpWidget(_host(
        child: ShiftDayColumn(
          date: date,
          closed: false,
          events: <TideEvent>[event],
          resourceById: _resourceMap,
          dropTime: dropTime,
          onShiftTap: tapped.add,
        ),
      ));

      await tester.tap(find.byKey(const ValueKey('shift-card-container')));
      await tester.pump();

      expect(tapped, hasLength(1));
      expect(tapped.single.id, 's1');
    });

    testWidgets(
        'an external drop on the column triggers onExternalDragEnd with '
        'the configured dropTime', (tester) async {
      final calls = <TideExternalDragEndDetails>[];

      await tester.pumpWidget(_host(
        child: ShiftDayColumn(
          date: date,
          closed: false,
          events: const <TideEvent>[],
          resourceById: _resourceMap,
          dropTime: dropTime,
          onExternalDragEnd: calls.add,
        ),
      ));

      // Use the shared notifier to simulate a drop landing on the column.
      final BuildContext ctx = tester.element(find.byType(ShiftDayColumn));
      final notifier = TideExternalDragScope.of(ctx);
      expect(notifier, isNotNull);

      // Hit-test against the column's render box: pick the global center.
      final RenderBox box =
          tester.renderObject(find.byType(ShiftDayColumn)) as RenderBox;
      final center = box.localToGlobal(box.size.center(Offset.zero));

      const data = TideExternalDragData(
        subject: 'Alice',
        duration: Duration(hours: 8),
        color: Color(0xFFFF0000),
        metadata: <String, dynamic>{'resourceId': 'alice'},
      );
      notifier!.drop(data, center);
      await tester.pump();

      expect(calls, hasLength(1));
      expect(calls.single.dropTime, equals(dropTime));
      expect(calls.single.data.subject, 'Alice');
    });
  });
}
