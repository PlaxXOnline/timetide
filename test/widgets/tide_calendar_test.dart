import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// Direct imports to avoid barrel file compilation issues with WIP files.
import 'package:timetide/src/core/controller.dart';
import 'package:timetide/src/core/datasource_in_memory.dart';
import 'package:timetide/src/core/models/resource.dart';
import 'package:timetide/src/core/models/view.dart';
import 'package:timetide/src/core/presets.dart';
import 'package:timetide/src/theme/tide_theme.dart';
import 'package:timetide/src/theme/tide_theme_data.dart';
import 'package:timetide/src/views/day/day_view.dart';
import 'package:timetide/src/views/month/month_view.dart';
import 'package:timetide/src/views/timeline_day/timeline_day_view.dart';
import 'package:timetide/src/views/view_switcher.dart';
import 'package:timetide/src/widgets/tide_calendar.dart';
import 'package:timetide/src/widgets/header/calendar_header.dart';
import 'package:timetide/src/widgets/header/view_switcher_bar.dart';
import 'package:timetide/src/widgets/resource_header/resource_header.dart';
import 'package:timetide/src/widgets/resource_header/resource_load_indicator.dart';

void main() {
  group('TideCalendar', () {
    late TideInMemoryDatasource datasource;

    setUp(() {
      datasource = TideInMemoryDatasource();
    });

    testWidgets('renders without error with datasource only', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideCalendar(datasource: datasource),
        ),
      );

      expect(find.byType(TideCalendar), findsOneWidget);
    });

    testWidgets('creates internal controller when none provided',
        (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideCalendar(datasource: datasource),
        ),
      );

      // The widget should render and have a view switcher child,
      // proving the internal controller is working.
      expect(find.byType(TideViewSwitcher), findsOneWidget);
    });

    testWidgets('uses external controller when provided', (tester) async {
      final controller = TideController(
        datasource: datasource,
        initialView: TideView.month,
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideCalendar(
            datasource: datasource,
            controller: controller,
          ),
        ),
      );

      expect(find.byType(TideCalendar), findsOneWidget);
      // The month view should be active since we set initialView to month.
      expect(find.byType(TideMonthView), findsOneWidget);
    });

    testWidgets('disposes internal controller on widget removal',
        (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideCalendar(datasource: datasource),
        ),
      );

      // Replace with a different widget to trigger dispose.
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox.shrink(),
        ),
      );

      // If internal controller dispose threw, the test would fail.
      expect(true, isTrue);
    });

    testWidgets('does not dispose external controller', (tester) async {
      final controller = TideController(
        datasource: datasource,
        initialView: TideView.week,
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideCalendar(
            datasource: datasource,
            controller: controller,
          ),
        ),
      );

      // Remove TideCalendar.
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox.shrink(),
        ),
      );

      // External controller should still be usable.
      expect(() => controller.currentView, returnsNormally);
      controller.dispose();
    });

    testWidgets('dispatches correct view for currentView', (tester) async {
      final controller = TideController(
        datasource: datasource,
        initialView: TideView.day,
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideCalendar(
            datasource: datasource,
            controller: controller,
          ),
        ),
      );

      expect(find.byType(TideDayView), findsOneWidget);

      // Switch to month view.
      controller.currentView = TideView.month;
      await tester.pumpAndSettle();

      expect(find.byType(TideMonthView), findsOneWidget);
    });

    testWidgets('wraps with TideTheme when themeData provided',
        (tester) async {
      const customTheme = TideThemeData(
        primaryColor: Color(0xFFFF0000),
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideCalendar(
            datasource: datasource,
            themeData: customTheme,
          ),
        ),
      );

      expect(find.byType(TideTheme), findsOneWidget);
    });

    testWidgets('does not wrap with TideTheme when themeData is null',
        (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideCalendar(datasource: datasource),
        ),
      );

      expect(find.byType(TideTheme), findsNothing);
    });

    testWidgets('preset factory applies config', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideCalendar.preset(
            TidePreset.salonDay,
            datasource: datasource,
          ),
        ),
      );

      // salonDay preset uses timelineDay view.
      expect(find.byType(TideTimelineDayView), findsOneWidget);
    });

    testWidgets('shows header by default', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideCalendar(datasource: datasource),
        ),
      );

      expect(find.byType(TideCalendarHeader), findsOneWidget);
    });

    testWidgets('hides header when showHeader is false', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideCalendar(
            datasource: datasource,
            showHeader: false,
          ),
        ),
      );

      expect(find.byType(TideCalendarHeader), findsNothing);
    });

    testWidgets('uses custom headerBuilder', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideCalendar(
            datasource: datasource,
            headerBuilder: (context, controller) =>
                const Text('Custom Header'),
          ),
        ),
      );

      expect(find.text('Custom Header'), findsOneWidget);
      expect(find.byType(TideCalendarHeader), findsNothing);
    });

    testWidgets('onViewChanged callback fires', (tester) async {
      TideView? changedTo;
      final controller = TideController(
        datasource: datasource,
        initialView: TideView.week,
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideCalendar(
            datasource: datasource,
            controller: controller,
            onViewChanged: (view) => changedTo = view,
          ),
        ),
      );

      controller.currentView = TideView.day;
      await tester.pump();

      expect(changedTo, TideView.day);
    });
  });

  group('TideCalendarHeader', () {
    late TideController controller;

    setUp(() {
      controller = TideController(
        datasource: TideInMemoryDatasource(),
        initialView: TideView.week,
      );
    });

    tearDown(() => controller.dispose());

    testWidgets('renders navigation buttons and today', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideCalendarHeader(controller: controller),
        ),
      );

      // Has previous and next buttons, and "Today" label.
      expect(find.text('\u25C0'), findsOneWidget);
      expect(find.text('\u25B6'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('shows view switcher when allowedViews provided',
        (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideCalendarHeader(
            controller: controller,
            allowedViews: [TideView.day, TideView.week, TideView.month],
          ),
        ),
      );

      expect(find.byType(TideViewSwitcherBar), findsOneWidget);
    });

    testWidgets('hides view switcher when single view', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideCalendarHeader(
            controller: controller,
            allowedViews: [TideView.week],
          ),
        ),
      );

      expect(find.byType(TideViewSwitcherBar), findsNothing);
    });
  });

  group('TideViewSwitcherBar', () {
    late TideController controller;

    setUp(() {
      controller = TideController(
        datasource: TideInMemoryDatasource(),
        initialView: TideView.week,
      );
    });

    tearDown(() => controller.dispose());

    testWidgets('shows allowed view labels', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideViewSwitcherBar(
            controller: controller,
            allowedViews: [TideView.day, TideView.week, TideView.month],
          ),
        ),
      );

      expect(find.text('Day'), findsOneWidget);
      expect(find.text('Week'), findsOneWidget);
      expect(find.text('Month'), findsOneWidget);
    });

    testWidgets('tap switches view', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideViewSwitcherBar(
            controller: controller,
            allowedViews: [TideView.day, TideView.week, TideView.month],
          ),
        ),
      );

      await tester.tap(find.text('Day'));
      await tester.pump();

      expect(controller.currentView, TideView.day);
    });
  });

  group('TideResourceHeader', () {
    testWidgets('shows resource name and color indicator', (tester) async {
      const resource = TideResource(
        id: 'r1',
        displayName: 'Room A',
        color: Color(0xFF4CAF50),
      );

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: TideResourceHeader(resource: resource),
        ),
      );

      expect(find.text('Room A'), findsOneWidget);
    });
  });

  group('TideResourceLoadIndicator', () {
    testWidgets('percentage mode renders bar', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 200,
            child: TideResourceLoadIndicator(
              mode: TideLoadDisplayMode.percentage,
              percentage: 0.75,
            ),
          ),
        ),
      );

      expect(find.byType(TideResourceLoadIndicator), findsOneWidget);
      expect(find.byType(FractionallySizedBox), findsOneWidget);
    });

    testWidgets('eventCount mode renders text', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: TideResourceLoadIndicator(
            mode: TideLoadDisplayMode.eventCount,
            eventCount: 5,
          ),
        ),
      );

      expect(find.text('5 events'), findsOneWidget);
    });

    testWidgets('custom mode uses builder', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TideResourceLoadIndicator(
            mode: TideLoadDisplayMode.custom,
            customBuilder: (context) => const Text('Custom load'),
          ),
        ),
      );

      expect(find.text('Custom load'), findsOneWidget);
    });
  });
}
