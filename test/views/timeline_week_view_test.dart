import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timetide/timetide.dart';

void main() {
  group('TideTimelineWeekView', () {
    late TideController controller;
    late TideInMemoryDatasource datasource;

    setUp(() {
      datasource = TideInMemoryDatasource(
        resources: [
          const TideResource(
            id: 'r1',
            displayName: 'Alice',
            color: Color(0xFF4CAF50),
          ),
          const TideResource(
            id: 'r2',
            displayName: 'Bob',
            color: Color(0xFF2196F3),
          ),
        ],
        events: [
          TideEvent(
            id: 'e1',
            subject: 'Sprint Planning',
            startTime: DateTime(2026, 3, 16, 9, 0),
            endTime: DateTime(2026, 3, 16, 10, 30),
            resourceIds: const ['r1'],
          ),
          TideEvent(
            id: 'e2',
            subject: 'Code Review',
            startTime: DateTime(2026, 3, 18, 14, 0),
            endTime: DateTime(2026, 3, 18, 15, 0),
            resourceIds: const ['r2'],
          ),
        ],
      );
      controller = TideController(
        datasource: datasource,
        initialView: TideView.timelineWeek,
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
              width: 1200,
              height: 600,
              child: TideTimelineWeekView(controller: controller),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TideTimelineWeekView), findsOneWidget);
    });

    testWidgets('shows resource headers', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideTheme(
            data: const TideThemeData(),
            child: SizedBox(
              width: 1200,
              height: 600,
              child: TideTimelineWeekView(controller: controller),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
    });

    testWidgets('shows day headers', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideTheme(
            data: const TideThemeData(),
            child: SizedBox(
              width: 1200,
              height: 600,
              child: TideTimelineWeekView(controller: controller),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should show day headers for the week.
      // The week of 2026-03-19 starts on Monday Mar 16.
      expect(find.text('Mon 16'), findsOneWidget);
      expect(find.text('Sun 22'), findsOneWidget);
    });

    testWidgets('has accessibility label', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideTheme(
            data: const TideThemeData(),
            child: SizedBox(
              width: 1200,
              height: 600,
              child: TideTimelineWeekView(controller: controller),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel('Timeline week view'),
        findsOneWidget,
      );
    });

    testWidgets('shows events', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideTheme(
            data: const TideThemeData(),
            child: SizedBox(
              width: 1200,
              height: 600,
              child: TideTimelineWeekView(controller: controller),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sprint Planning'), findsOneWidget);
      expect(find.text('Code Review'), findsOneWidget);
    });
  });
}
