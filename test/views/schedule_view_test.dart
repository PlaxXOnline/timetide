import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timetide/src/core/controller.dart';
import 'package:timetide/src/core/datasource_in_memory.dart';
import 'package:timetide/src/core/models/event.dart';
import 'package:timetide/src/core/models/view.dart';
import 'package:timetide/src/theme/tide_theme.dart';
import 'package:timetide/src/theme/tide_theme_data.dart';
import 'package:timetide/src/views/schedule/schedule_item.dart';
import 'package:timetide/src/views/schedule/schedule_view.dart';

void main() {
  late TideController controller;
  late TideInMemoryDatasource datasource;

  setUp(() {
    datasource = TideInMemoryDatasource(events: [
      TideEvent(
        id: '1',
        subject: 'Team Standup',
        startTime: DateTime(2026, 3, 19, 10, 0),
        endTime: DateTime(2026, 3, 19, 10, 30),
      ),
      TideEvent(
        id: '2',
        subject: 'Design Review',
        startTime: DateTime(2026, 3, 20, 14, 0),
        endTime: DateTime(2026, 3, 20, 15, 0),
        location: 'Room 42',
      ),
      TideEvent(
        id: '3',
        subject: 'All Day Workshop',
        startTime: DateTime(2026, 3, 21),
        endTime: DateTime(2026, 3, 22),
        isAllDay: true,
      ),
    ]);
    controller = TideController(
      datasource: datasource,
      initialView: TideView.schedule,
      initialDate: DateTime(2026, 3, 19),
    );
  });

  tearDown(() {
    controller.dispose();
  });

  Widget buildTestWidget({TideScheduleView? view}) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: TideTheme(
        data: const TideThemeData(),
        child: view ?? TideScheduleView(controller: controller),
      ),
    );
  }

  testWidgets('renders schedule view', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.byType(TideScheduleView), findsOneWidget);
  });

  testWidgets('shows events in chronological order', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Team Standup'), findsOneWidget);
    expect(find.text('Design Review'), findsOneWidget);
  });

  testWidgets('shows date headers', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Date headers should contain weekday and date
    expect(find.textContaining('Mar'), findsWidgets);
  });

  testWidgets('shows location when available', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Room 42'), findsOneWidget);
  });

  testWidgets('shows empty state when no events', (tester) async {
    final emptyController = TideController(
      datasource: TideInMemoryDatasource(),
      initialView: TideView.schedule,
      initialDate: DateTime(2026, 3, 19),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: TideTheme(
          data: const TideThemeData(),
          child: TideScheduleView(controller: emptyController),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No events'), findsOneWidget);

    emptyController.dispose();
  });

  testWidgets('fires onEventTap callback', (tester) async {
    TideEvent? tappedEvent;

    await tester.pumpWidget(buildTestWidget(
      view: TideScheduleView(
        controller: controller,
        onEventTap: (event) => tappedEvent = event,
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Team Standup'));
    expect(tappedEvent?.id, '1');
  });

  testWidgets('uses custom event builder', (tester) async {
    await tester.pumpWidget(buildTestWidget(
      view: TideScheduleView(
        controller: controller,
        eventBuilder: (context, event) {
          return Padding(
            padding: const EdgeInsets.all(8),
            child: Text('Custom: ${event.subject}'),
          );
        },
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Custom: Team Standup'), findsOneWidget);
  });

  testWidgets('uses custom empty builder', (tester) async {
    final emptyController = TideController(
      datasource: TideInMemoryDatasource(),
      initialDate: DateTime(2026, 3, 19),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: TideTheme(
          data: const TideThemeData(),
          child: TideScheduleView(
            controller: emptyController,
            emptyBuilder: (context) => const Text('Nothing scheduled'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nothing scheduled'), findsOneWidget);

    emptyController.dispose();
  });

  testWidgets('schedule item shows all-day label', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: TideTheme(
          data: const TideThemeData(),
          child: TideScheduleItem(
            event: TideEvent(
              id: '3',
              subject: 'All Day Workshop',
              startTime: DateTime(2026, 3, 21),
              endTime: DateTime(2026, 3, 22),
              isAllDay: true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('All day'), findsOneWidget);
    expect(find.text('All Day Workshop'), findsOneWidget);
  });

  testWidgets('has semantics label', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    final semantics =
        tester.getSemantics(find.byType(TideScheduleView).first);
    expect(semantics.label, contains('Schedule view'));
  });
}
