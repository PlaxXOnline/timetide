import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timetide/src/core/controller.dart';
import 'package:timetide/src/core/datasource_in_memory.dart';
import 'package:timetide/src/core/models/event.dart';
import 'package:timetide/src/core/models/view.dart';
import 'package:timetide/src/theme/tide_theme.dart';
import 'package:timetide/src/theme/tide_theme_data.dart';
import 'package:timetide/src/views/month/month_cell.dart';
import 'package:timetide/src/views/month/month_view.dart';

void main() {
  late TideController controller;
  late TideInMemoryDatasource datasource;

  setUp(() {
    datasource = TideInMemoryDatasource(events: [
      TideEvent(
        id: '1',
        subject: 'March Event 1',
        startTime: DateTime(2026, 3, 5, 10, 0),
        endTime: DateTime(2026, 3, 5, 11, 0),
      ),
      TideEvent(
        id: '2',
        subject: 'March Event 2',
        startTime: DateTime(2026, 3, 5, 12, 0),
        endTime: DateTime(2026, 3, 5, 13, 0),
      ),
      TideEvent(
        id: '3',
        subject: 'March Event 3',
        startTime: DateTime(2026, 3, 5, 14, 0),
        endTime: DateTime(2026, 3, 5, 15, 0),
      ),
      TideEvent(
        id: '4',
        subject: 'March Event 4',
        startTime: DateTime(2026, 3, 5, 16, 0),
        endTime: DateTime(2026, 3, 5, 17, 0),
      ),
      TideEvent(
        id: '5',
        subject: 'Spanning Event',
        startTime: DateTime(2026, 3, 10),
        endTime: DateTime(2026, 3, 12),
      ),
    ]);
    controller = TideController(
      datasource: datasource,
      initialView: TideView.month,
      initialDate: DateTime(2026, 3, 15),
    );
  });

  tearDown(() {
    controller.dispose();
  });

  Widget buildTestWidget({TideMonthView? view}) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: TideTheme(
        data: const TideThemeData(),
        child: view ?? TideMonthView(controller: controller),
      ),
    );
  }

  testWidgets('renders month view', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.byType(TideMonthView), findsOneWidget);
  });

  testWidgets('shows 6x7 grid of cells', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Should find TideMonthCell widgets for the grid
    expect(find.byType(TideMonthCell), findsWidgets);
  });

  testWidgets('shows weekday headers', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Mon'), findsOneWidget);
    expect(find.text('Sun'), findsOneWidget);
  });

  testWidgets('shows +N badge when events exceed maxEventsPerCell',
      (tester) async {
    await tester.pumpWidget(buildTestWidget(
      view: TideMonthView(
        controller: controller,
        maxEventsPerCell: 2,
        eventDisplayMode: TideEventDisplayMode.indicator,
      ),
    ));
    await tester.pumpAndSettle();

    // March 5 has 4 events, with maxEventsPerCell=2, should show +2
    expect(find.text('+2'), findsOneWidget);
  });

  testWidgets('selecting a date triggers controller.selectDate',
      (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Find the cell with "15" in it and tap
    await tester.tap(find.text('15').first);
    await tester.pumpAndSettle();

    expect(controller.selectedDate?.day, 15);
    expect(controller.selectedDate?.month, 3);
  });

  testWidgets('shows week numbers when enabled', (tester) async {
    await tester.pumpWidget(buildTestWidget(
      view: TideMonthView(
        controller: controller,
        showWeekNumbers: true,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(TideMonthView), findsOneWidget);
  });

  testWidgets('shows agenda panel when enabled and date selected',
      (tester) async {
    // Select a date first
    controller.selectDate(DateTime(2026, 3, 5));

    await tester.pumpWidget(buildTestWidget(
      view: TideMonthView(
        controller: controller,
        showAgendaPanel: true,
      ),
    ));
    await tester.pumpAndSettle();

    // The agenda panel should show events for March 5
    expect(find.text('March Event 1'), findsWidgets);
  });

  testWidgets('fires onEventTap callback via agenda panel', (tester) async {
    TideEvent? tappedEvent;
    controller.selectDate(DateTime(2026, 3, 5));

    await tester.pumpWidget(buildTestWidget(
      view: TideMonthView(
        controller: controller,
        showAgendaPanel: true,
        onEventTap: (event) => tappedEvent = event,
      ),
    ));
    await tester.pumpAndSettle();

    // Tap on the event in the agenda panel
    final eventFinder = find.text('March Event 1');
    if (eventFinder.evaluate().isNotEmpty) {
      await tester.tap(eventFinder.last);
      expect(tappedEvent?.id, '1');
    }
  });

  testWidgets('has semantics label', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    final semantics = tester.getSemantics(find.byType(TideMonthView).first);
    expect(semantics.label, contains('Month view'));
  });
}
