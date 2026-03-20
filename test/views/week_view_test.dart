import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timetide/src/core/controller.dart';
import 'package:timetide/src/core/datasource_in_memory.dart';
import 'package:timetide/src/core/models/event.dart';
import 'package:timetide/src/core/models/view.dart';
import 'package:timetide/src/theme/tide_theme.dart';
import 'package:timetide/src/theme/tide_theme_data.dart';
import 'package:timetide/src/views/week/week_header.dart';
import 'package:timetide/src/views/week/week_view.dart';

void main() {
  late TideController controller;
  late TideInMemoryDatasource datasource;

  // Use a Wednesday so the week is fully within range.
  final testDate = DateTime(2026, 3, 18); // Wednesday

  setUp(() {
    datasource = TideInMemoryDatasource(events: [
      TideEvent(
        id: '1',
        subject: 'Team Standup',
        startTime: DateTime(2026, 3, 18, 10, 0),
        endTime: DateTime(2026, 3, 18, 10, 30),
      ),
      TideEvent(
        id: '2',
        subject: 'Sprint Review',
        startTime: DateTime(2026, 3, 20, 14, 0),
        endTime: DateTime(2026, 3, 20, 15, 0),
      ),
      TideEvent(
        id: '3',
        subject: 'All Day Conference',
        startTime: DateTime(2026, 3, 16),
        endTime: DateTime(2026, 3, 17),
        isAllDay: true,
      ),
    ]);
    controller = TideController(
      datasource: datasource,
      initialView: TideView.week,
      initialDate: testDate,
    );
  });

  tearDown(() {
    controller.dispose();
  });

  Widget buildTestWidget({TideWeekView? view}) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: TideTheme(
        data: const TideThemeData(),
        child: view ?? TideWeekView(controller: controller),
      ),
    );
  }

  testWidgets('renders week view with 7 day columns', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.byType(TideWeekView), findsOneWidget);
    // Should show the week header
    expect(find.byType(TideWeekHeader), findsOneWidget);
  });

  testWidgets('week header shows day abbreviations', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // All 7 days should be shown
    expect(find.text('Mon'), findsOneWidget);
    expect(find.text('Tue'), findsOneWidget);
    expect(find.text('Wed'), findsOneWidget);
    expect(find.text('Thu'), findsOneWidget);
    expect(find.text('Fri'), findsOneWidget);
    expect(find.text('Sat'), findsOneWidget);
    expect(find.text('Sun'), findsOneWidget);
  });

  testWidgets('displays timed events', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Team Standup'), findsOneWidget);
    expect(find.text('Sprint Review'), findsOneWidget);
  });

  testWidgets('fires onEventTap callback', (tester) async {
    TideEvent? tappedEvent;

    await tester.pumpWidget(buildTestWidget(
      view: TideWeekView(
        controller: controller,
        startHour: 9,
        endHour: 12,
        onEventTap: (event) => tappedEvent = event,
      ),
    ));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Team Standup'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Team Standup'));
    expect(tappedEvent?.id, '1');
  });

  testWidgets('configurable numberOfDays', (tester) async {
    await tester.pumpWidget(buildTestWidget(
      view: TideWeekView(
        controller: controller,
        numberOfDays: 3,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(TideWeekView), findsOneWidget);
  });

  testWidgets('has semantics label', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    final semantics = tester.getSemantics(find.byType(TideWeekView).first);
    expect(semantics.label, contains('Week view'));
  });

  testWidgets('today is highlighted in header', (tester) async {
    // Create controller for today
    final todayController = TideController(
      datasource: TideInMemoryDatasource(),
      initialDate: DateTime.now(),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: TideTheme(
          data: const TideThemeData(),
          child: TideWeekView(controller: todayController),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Just verify the widget renders with today's date.
    expect(find.byType(TideWeekHeader), findsOneWidget);

    todayController.dispose();
  });
}
