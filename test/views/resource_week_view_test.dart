import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timetide/src/core/controller.dart';
import 'package:timetide/src/core/datasource_in_memory.dart';
import 'package:timetide/src/core/models/event.dart';
import 'package:timetide/src/core/models/resource.dart';
import 'package:timetide/src/core/models/view.dart';
import 'package:timetide/src/theme/tide_theme.dart';
import 'package:timetide/src/theme/tide_theme_data.dart';
import 'package:timetide/src/views/resource_week/resource_week_view.dart';
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

  // Monday 2026-03-16 through Sunday 2026-03-22.
  final events = [
    TideEvent(
      id: '1',
      subject: 'Alice Monday',
      startTime: DateTime(2026, 3, 16, 9, 0),
      endTime: DateTime(2026, 3, 16, 10, 0),
      resourceIds: ['alice'],
    ),
    TideEvent(
      id: '2',
      subject: 'Bob Wednesday',
      startTime: DateTime(2026, 3, 18, 10, 0),
      endTime: DateTime(2026, 3, 18, 11, 0),
      resourceIds: ['bob'],
    ),
    TideEvent(
      id: '3',
      subject: 'Shared Friday',
      startTime: DateTime(2026, 3, 20, 14, 0),
      endTime: DateTime(2026, 3, 20, 15, 0),
    ),
  ];

  setUp(() {
    datasource = TideInMemoryDatasource(
      events: events,
      resources: resources,
    );
    controller = TideController(
      datasource: datasource,
      initialView: TideView.resourceWeek,
      initialDate: DateTime(2026, 3, 16),
    );
  });

  tearDown(() {
    controller.dispose();
  });

  Widget buildTestWidget({TideResourceWeekView? view}) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: TideTheme(
        data: const TideThemeData(),
        child: view ??
            TideResourceWeekView(
              controller: controller,
              startHour: 0,
              endHour: 24,
            ),
      ),
    );
  }

  testWidgets('renders resource week view', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.byType(TideResourceWeekView), findsOneWidget);
  });

  testWidgets('renders resource headers', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.byType(TideResourceHeader), findsNWidgets(2));
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
  });

  testWidgets('renders day abbreviation sub-headers', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Each resource gets the same set of day abbreviations.
    // 7 days × 2 resources = 14 total day labels.
    expect(find.text('Mo'), findsNWidgets(2));
    expect(find.text('Tu'), findsNWidgets(2));
    expect(find.text('We'), findsNWidgets(2));
    expect(find.text('Th'), findsNWidgets(2));
    expect(find.text('Fr'), findsNWidgets(2));
    expect(find.text('Sa'), findsNWidgets(2));
    expect(find.text('Su'), findsNWidgets(2));
  });

  testWidgets('displays events in correct resource columns', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Alice Monday'), findsOneWidget);
    expect(find.text('Bob Wednesday'), findsOneWidget);
  });

  testWidgets('shared events appear in all resource columns', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Shared Friday'), findsNWidgets(2));
  });

  testWidgets('showWeekends=false hides Saturday and Sunday',
      (tester) async {
    await tester.pumpWidget(buildTestWidget(
      view: TideResourceWeekView(
        controller: controller,
        startHour: 0,
        endHour: 24,
        showWeekends: false,
      ),
    ));
    await tester.pumpAndSettle();

    // Only weekday abbreviations: 5 days × 2 resources = 10.
    expect(find.text('Mo'), findsNWidgets(2));
    expect(find.text('Fr'), findsNWidgets(2));
    expect(find.text('Sa'), findsNothing);
    expect(find.text('Su'), findsNothing);
  });

  testWidgets('custom resourceHeaderBuilder is used', (tester) async {
    await tester.pumpWidget(buildTestWidget(
      view: TideResourceWeekView(
        controller: controller,
        startHour: 0,
        endHour: 24,
        resourceHeaderBuilder: (context, resource) {
          return Text('Team: ${resource.displayName}');
        },
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Team: Alice'), findsOneWidget);
    expect(find.text('Team: Bob'), findsOneWidget);
  });

  testWidgets('renders with DnD enabled', (tester) async {
    await tester.pumpWidget(buildTestWidget(
      view: TideResourceWeekView(
        controller: controller,
        startHour: 0,
        endHour: 24,
        allowDragAndDrop: true,
        allowResize: true,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(TideResourceWeekView), findsOneWidget);
  });

  testWidgets('wraps content in Semantics widget', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    final semantics = tester.widget<Semantics>(
      find.descendant(
        of: find.byType(TideResourceWeekView),
        matching: find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == 'Resource week view',
        ),
      ),
    );
    expect(semantics.properties.label, 'Resource week view');
  });
}
