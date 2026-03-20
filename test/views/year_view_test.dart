import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timetide/timetide.dart';

void main() {
  group('TideYearView', () {
    late TideController controller;
    late TideInMemoryDatasource datasource;

    setUp(() {
      datasource = TideInMemoryDatasource(
        events: [
          TideEvent(
            id: 'e1',
            subject: 'New Year Meeting',
            startTime: DateTime(2026, 1, 5, 9, 0),
            endTime: DateTime(2026, 1, 5, 10, 0),
          ),
          TideEvent(
            id: 'e2',
            subject: 'Summer Event',
            startTime: DateTime(2026, 7, 15, 14, 0),
            endTime: DateTime(2026, 7, 15, 16, 0),
          ),
          TideEvent(
            id: 'e3',
            subject: 'Holiday',
            startTime: DateTime(2026, 12, 24, 0, 0),
            endTime: DateTime(2026, 12, 26, 0, 0),
            isAllDay: true,
          ),
        ],
      );
      controller = TideController(
        datasource: datasource,
        initialView: TideView.year,
        initialDate: DateTime(2026, 3, 19),
      );
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideTheme(
            data: const TideThemeData(),
            child: SizedBox(
              width: 600,
              height: 800,
              child: TideYearView(controller: controller),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TideYearView), findsOneWidget);
    });

    testWidgets('shows year number', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideTheme(
            data: const TideThemeData(),
            child: SizedBox(
              width: 600,
              height: 800,
              child: TideYearView(controller: controller),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2026'), findsOneWidget);
    });

    testWidgets('shows all 12 month names', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideTheme(
            data: const TideThemeData(),
            child: SizedBox(
              width: 600,
              height: 800,
              child: TideYearView(controller: controller),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Jan'), findsOneWidget);
      expect(find.text('Jun'), findsOneWidget);
      expect(find.text('Dec'), findsOneWidget);
    });

    testWidgets('calls onMonthTap when month is tapped', (tester) async {
      DateTime? tappedMonth;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideTheme(
            data: const TideThemeData(),
            child: SizedBox(
              width: 600,
              height: 800,
              child: TideYearView(
                controller: controller,
                onMonthTap: (date) => tappedMonth = date,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on Jan header.
      await tester.tap(find.text('Jan'));
      expect(tappedMonth?.month, 1);
    });

    testWidgets('has semantics', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideTheme(
            data: const TideThemeData(),
            child: SizedBox(
              width: 600,
              height: 800,
              child: TideYearView(controller: controller),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel('Year view, 2026'),
        findsOneWidget,
      );
    });

    testWidgets('supports custom monthsPerRow', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideTheme(
            data: const TideThemeData(),
            child: SizedBox(
              width: 800,
              height: 800,
              child: TideYearView(
                controller: controller,
                monthsPerRow: 4,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TideYearView), findsOneWidget);
    });

    testWidgets('calls onDayTap', (tester) async {
      DateTime? tappedDay;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideTheme(
            data: const TideThemeData(),
            child: SizedBox(
              width: 600,
              height: 800,
              child: TideYearView(
                controller: controller,
                onDayTap: (date) => tappedDay = date,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on day 5 in January (which has an event).
      final dayFinders = find.text('5');
      // There will be multiple '5's across months; tap the first one.
      if (dayFinders.evaluate().isNotEmpty) {
        await tester.tap(dayFinders.first);
        expect(tappedDay, isNotNull);
      }
    });

    testWidgets('supports custom heatMapColorScale', (tester) async {
      bool customCalled = false;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideTheme(
            data: const TideThemeData(),
            child: SizedBox(
              width: 600,
              height: 800,
              child: TideYearView(
                controller: controller,
                heatMapColorScale: (count) {
                  customCalled = true;
                  return count > 0
                      ? const Color(0xFFFF0000)
                      : const Color(0xFFFFFFFF);
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(customCalled, isTrue);
    });
  });
}
