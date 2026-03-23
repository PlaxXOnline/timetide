import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timetide/src/core/controller.dart';
import 'package:timetide/src/core/datasource_in_memory.dart';
import 'package:timetide/src/core/models/event.dart';
import 'package:timetide/src/core/models/resource.dart';
import 'package:timetide/src/core/models/view.dart';
import 'package:timetide/src/theme/tide_theme.dart';
import 'package:timetide/src/theme/tide_theme_data.dart';
import 'package:timetide/src/views/resource_day/resource_day_view.dart';
import 'package:timetide/src/widgets/resource_header/resource_header.dart';

void main() {
  late TideController controller;
  late TideInMemoryDatasource datasource;

  final resources = [
    const TideResource(
      id: 'alice',
      displayName: 'Alice',
      color: Color(0xFF2196F3),
    ),
    const TideResource(
      id: 'bob',
      displayName: 'Bob',
      color: Color(0xFF4CAF50),
    ),
  ];

  final events = [
    TideEvent(
      id: '1',
      subject: 'Alice Meeting',
      startTime: DateTime(2026, 3, 19, 9, 0),
      endTime: DateTime(2026, 3, 19, 10, 0),
      resourceIds: ['alice'],
    ),
    TideEvent(
      id: '2',
      subject: 'Bob Design',
      startTime: DateTime(2026, 3, 19, 10, 0),
      endTime: DateTime(2026, 3, 19, 11, 0),
      resourceIds: ['bob'],
    ),
    TideEvent(
      id: '3',
      subject: 'Shared Event',
      startTime: DateTime(2026, 3, 19, 14, 0),
      endTime: DateTime(2026, 3, 19, 15, 0),
    ),
  ];

  setUp(() {
    datasource = TideInMemoryDatasource(
      events: events,
      resources: resources,
    );
    controller = TideController(
      datasource: datasource,
      initialView: TideView.resourceDay,
      initialDate: DateTime(2026, 3, 19),
    );
  });

  tearDown(() {
    controller.dispose();
  });

  Widget buildTestWidget({TideResourceDayView? view}) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: TideTheme(
        data: const TideThemeData(),
        child: view ??
            TideResourceDayView(
              controller: controller,
              startHour: 0,
              endHour: 24,
            ),
      ),
    );
  }

  testWidgets('renders resource day view', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.byType(TideResourceDayView), findsOneWidget);
  });

  testWidgets('renders correct number of resource columns', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.byType(TideResourceHeader), findsNWidgets(2));
  });

  testWidgets('resource headers show names', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
  });

  testWidgets('displays events filtered by resource', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Alice Meeting'), findsOneWidget);
    expect(find.text('Bob Design'), findsOneWidget);
  });

  testWidgets('shared events appear in all columns', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Event with no resourceIds appears in all resource columns.
    expect(find.text('Shared Event'), findsNWidgets(2));
  });

  testWidgets('empty resource column renders without error', (tester) async {
    final emptyDatasource = TideInMemoryDatasource(
      events: [],
      resources: resources,
    );
    final emptyController = TideController(
      datasource: emptyDatasource,
      initialView: TideView.resourceDay,
      initialDate: DateTime(2026, 3, 19),
    );
    addTearDown(emptyController.dispose);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: TideTheme(
          data: const TideThemeData(),
          child: TideResourceDayView(
            controller: emptyController,
            startHour: 0,
            endHour: 24,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TideResourceDayView), findsOneWidget);
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
  });

  testWidgets('custom resourceHeaderBuilder is used', (tester) async {
    await tester.pumpWidget(buildTestWidget(
      view: TideResourceDayView(
        controller: controller,
        startHour: 0,
        endHour: 24,
        resourceHeaderBuilder: (context, resource) {
          return Text('Custom: ${resource.displayName}');
        },
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Custom: Alice'), findsOneWidget);
    expect(find.text('Custom: Bob'), findsOneWidget);
  });

  testWidgets('custom eventBuilder is used', (tester) async {
    await tester.pumpWidget(buildTestWidget(
      view: TideResourceDayView(
        controller: controller,
        startHour: 0,
        endHour: 24,
        eventBuilder: (context, event) {
          return Text('Custom: ${event.subject}');
        },
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Custom: Alice Meeting'), findsOneWidget);
    expect(find.text('Custom: Bob Design'), findsOneWidget);
  });

  testWidgets('renders with DnD enabled', (tester) async {
    await tester.pumpWidget(buildTestWidget(
      view: TideResourceDayView(
        controller: controller,
        startHour: 0,
        endHour: 24,
        allowDragAndDrop: true,
        allowResize: true,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(TideResourceDayView), findsOneWidget);
    expect(find.text('Alice Meeting'), findsOneWidget);
  });

  testWidgets('wraps content in Semantics widget', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    final semantics = tester.widget<Semantics>(
      find.descendant(
        of: find.byType(TideResourceDayView),
        matching: find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == 'Resource day view',
        ),
      ),
    );
    expect(semantics.properties.label, 'Resource day view');
  });
}
