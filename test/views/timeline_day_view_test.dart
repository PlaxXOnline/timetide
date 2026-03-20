import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timetide/timetide.dart';

void main() {
  group('TideTimelineDayView', () {
    late TideController controller;
    late TideInMemoryDatasource datasource;

    setUp(() {
      datasource = TideInMemoryDatasource(
        resources: [
          const TideResource(
            id: 'r1',
            displayName: 'Room A',
            color: Color(0xFF4CAF50),
          ),
          const TideResource(
            id: 'r2',
            displayName: 'Room B',
            color: Color(0xFF2196F3),
          ),
        ],
        events: [
          TideEvent(
            id: 'e1',
            subject: 'Meeting',
            startTime: DateTime(2026, 3, 19, 9, 0),
            endTime: DateTime(2026, 3, 19, 10, 0),
            resourceIds: const ['r1'],
          ),
          TideEvent(
            id: 'e2',
            subject: 'Workshop',
            startTime: DateTime(2026, 3, 19, 14, 0),
            endTime: DateTime(2026, 3, 19, 16, 0),
            resourceIds: const ['r2'],
          ),
        ],
      );
      controller = TideController(
        datasource: datasource,
        initialView: TideView.timelineDay,
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
            child: TideTimelineDayView(controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TideTimelineDayView), findsOneWidget);
    });

    testWidgets('shows resource headers', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideTheme(
            data: const TideThemeData(),
            child: SizedBox(
              width: 800,
              height: 600,
              child: TideTimelineDayView(controller: controller),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Room A'), findsOneWidget);
      expect(find.text('Room B'), findsOneWidget);
    });

    testWidgets('shows event subjects', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideTheme(
            data: const TideThemeData(),
            child: SizedBox(
              width: 800,
              height: 600,
              child: TideTimelineDayView(controller: controller),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Meeting'), findsOneWidget);
      expect(find.text('Workshop'), findsOneWidget);
    });

    testWidgets('has semantics labels', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideTheme(
            data: const TideThemeData(),
            child: SizedBox(
              width: 800,
              height: 600,
              child: TideTimelineDayView(controller: controller),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel('Timeline day view'),
        findsOneWidget,
      );
    });

    testWidgets('calls onEventTap when event is tapped', (tester) async {
      TideEvent? tappedEvent;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideTheme(
            data: const TideThemeData(),
            child: SizedBox(
              width: 800,
              height: 600,
              child: TideTimelineDayView(
                controller: controller,
                startHour: 8,
                endHour: 18,
                hourWidth: 60.0,
                resourceHeaderWidth: 100.0,
                onEventTap: (event) => tappedEvent = event,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Meeting at 9:00 with hourWidth 60 and startHour 8:
      // left = (9-8)*60 = 60, plus resourceHeaderWidth 100 offset in the
      // scroll area. Should be visible.
      final meetingFinder = find.text('Meeting');
      if (meetingFinder.evaluate().isNotEmpty) {
        await tester.tap(meetingFinder, warnIfMissed: false);
      }
      expect(tappedEvent?.id, 'e1');
    });

    testWidgets('respects custom resourceHeaderWidth', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideTheme(
            data: const TideThemeData(),
            child: SizedBox(
              width: 800,
              height: 600,
              child: TideTimelineDayView(
                controller: controller,
                resourceHeaderWidth: 200.0,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should render without errors at wider header width.
      expect(find.byType(TideTimelineDayView), findsOneWidget);
    });

    testWidgets('renders time labels', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideTheme(
            data: const TideThemeData(),
            child: SizedBox(
              width: 800,
              height: 600,
              child: TideTimelineDayView(
                controller: controller,
                startHour: 8,
                endHour: 18,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('08:00'), findsOneWidget);
      expect(find.text('12:00'), findsOneWidget);
    });
  });

  group('TideResourceRow', () {
    testWidgets('renders events horizontally', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideTheme(
            data: const TideThemeData(),
            child: SizedBox(
              width: 800,
              height: 60,
              child: TideResourceRow(
                events: [
                  TideEvent(
                    id: 'e1',
                    subject: 'Task',
                    startTime: DateTime(2026, 3, 19, 10, 0),
                    endTime: DateTime(2026, 3, 19, 11, 0),
                  ),
                ],
                startHour: 0,
                endHour: 24,
                hourWidth: 80,
                rowHeight: 60,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Task'), findsOneWidget);
    });
  });
}
