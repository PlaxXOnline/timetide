import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timetide/timetide.dart';

void main() {
  group('TideMultiWeekView', () {
    late TideController controller;
    late TideInMemoryDatasource datasource;

    setUp(() {
      datasource = TideInMemoryDatasource(
        events: [
          TideEvent(
            id: 'e1',
            subject: 'Standup',
            startTime: DateTime(2026, 3, 19, 9, 0),
            endTime: DateTime(2026, 3, 19, 9, 15),
          ),
          TideEvent(
            id: 'e2',
            subject: 'Retro',
            startTime: DateTime(2026, 3, 20, 14, 0),
            endTime: DateTime(2026, 3, 20, 15, 0),
          ),
        ],
      );
      controller = TideController(
        datasource: datasource,
        initialView: TideView.multiWeek,
        initialDate: DateTime(2026, 3, 19),
        numberOfWeeksInMultiWeek: 2,
      );
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('renders with default 2 weeks', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideTheme(
            data: const TideThemeData(),
            child: SizedBox(
              width: 700,
              height: 400,
              child: TideMultiWeekView(
                controller: controller,
                numberOfWeeks: 2,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TideMultiWeekView), findsOneWidget);
    });

    testWidgets('shows day-of-week headers', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideTheme(
            data: const TideThemeData(),
            child: SizedBox(
              width: 700,
              height: 400,
              child: TideMultiWeekView(
                controller: controller,
                numberOfWeeks: 2,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Fri'), findsOneWidget);
      expect(find.text('Sun'), findsOneWidget);
    });

    testWidgets('displays events in cells', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideTheme(
            data: const TideThemeData(),
            child: SizedBox(
              width: 700,
              height: 400,
              child: TideMultiWeekView(
                controller: controller,
                numberOfWeeks: 2,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Standup'), findsOneWidget);
      expect(find.text('Retro'), findsOneWidget);
    });

    testWidgets('calls onDateTap', (tester) async {
      DateTime? tappedDate;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideTheme(
            data: const TideThemeData(),
            child: SizedBox(
              width: 700,
              height: 400,
              child: TideMultiWeekView(
                controller: controller,
                numberOfWeeks: 2,
                onDateTap: (date) => tappedDate = date,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on a date cell.
      await tester.tap(find.text('19').first);
      expect(tappedDate, isNotNull);
    });

    testWidgets('has semantics', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideTheme(
            data: const TideThemeData(),
            child: SizedBox(
              width: 700,
              height: 400,
              child: TideMultiWeekView(
                controller: controller,
                numberOfWeeks: 3,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify the Semantics widget with the expected label exists.
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.label == 'Multi-week view, 3 weeks',
        ),
        findsOneWidget,
      );
    });

    testWidgets('supports up to 6 weeks', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideTheme(
            data: const TideThemeData(),
            child: SizedBox(
              width: 700,
              height: 800,
              child: TideMultiWeekView(
                controller: controller,
                numberOfWeeks: 6,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TideMultiWeekView), findsOneWidget);
    });

    testWidgets('shows +N more when events exceed maxEventsPerCell',
        (tester) async {
      final manyEvents = TideInMemoryDatasource(
        events: List.generate(
          5,
          (i) => TideEvent(
            id: 'e$i',
            subject: 'Event $i',
            startTime: DateTime(2026, 3, 19, 9 + i, 0),
            endTime: DateTime(2026, 3, 19, 10 + i, 0),
          ),
        ),
      );
      final ctrl = TideController(
        datasource: manyEvents,
        initialView: TideView.multiWeek,
        initialDate: DateTime(2026, 3, 19),
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideTheme(
            data: const TideThemeData(),
            child: SizedBox(
              width: 700,
              height: 400,
              child: TideMultiWeekView(
                controller: ctrl,
                numberOfWeeks: 2,
                maxEventsPerCell: 2,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('+3 more'), findsOneWidget);

      ctrl.dispose();
    });
  });
}
