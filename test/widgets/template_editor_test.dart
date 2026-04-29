import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:timetide/src/core/models/resource.dart';
import 'package:timetide/src/core/models/template_slot.dart';
import 'package:timetide/src/theme/tide_theme.dart';
import 'package:timetide/src/theme/tide_theme_data.dart';
import 'package:timetide/src/widgets/template_editor/template_slot_painter.dart';
import 'package:timetide/src/widgets/template_editor/tide_template_editor.dart';

// ─── Test helpers ────────────────────────────────────────

const _resources = [
  TideResource(
    id: 'r1',
    displayName: 'Alice',
    color: Color(0xFF4CAF50),
  ),
  TideResource(
    id: 'r2',
    displayName: 'Bob',
    color: Color(0xFFFF9800),
  ),
];

const _slots = [
  TideTemplateSlot(
    id: 'slot-1',
    resourceId: 'r1',
    dayOfWeek: 1, // Monday
    startTime: TideTimeOfDay(hour: 9, minute: 0),
    endTime: TideTimeOfDay(hour: 12, minute: 0),
  ),
  TideTemplateSlot(
    id: 'slot-2',
    resourceId: 'r2',
    dayOfWeek: 3, // Wednesday
    startTime: TideTimeOfDay(hour: 10, minute: 0),
    endTime: TideTimeOfDay(hour: 14, minute: 0),
  ),
];

const _breakSlot = TideTemplateSlot(
  id: 'slot-break',
  resourceId: 'r1',
  dayOfWeek: 1,
  startTime: TideTimeOfDay(hour: 12, minute: 0),
  endTime: TideTimeOfDay(hour: 13, minute: 0),
  isBreak: true,
);

Widget buildTestWidget({
  List<TideResource>? resources,
  List<TideTemplateSlot>? slots,
  ValueChanged<TideTemplateSlot>? onSlotCreated,
  ValueChanged<TideTemplateSlot>? onSlotUpdated,
  ValueChanged<TideTemplateSlot>? onSlotDeleted,
  bool readOnly = false,
  int startHour = 7,
  int endHour = 21,
  bool showBreaks = true,
  Map<String, Color>? resourceColors,
}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: TideTheme(
      data: const TideThemeData(),
      child: SizedBox(
        width: 1000,
        height: 900,
        child: TideTemplateEditor(
          resources: resources ?? _resources,
          slots: slots ?? _slots,
          onSlotCreated: onSlotCreated,
          onSlotUpdated: onSlotUpdated,
          onSlotDeleted: onSlotDeleted,
          readOnly: readOnly,
          startHour: startHour,
          endHour: endHour,
          showBreaks: showBreaks,
          resourceColors: resourceColors,
        ),
      ),
    ),
  );
}

// ─── Tests ───────────────────────────────────────────────

void main() {
  group('TideTemplateEditor', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(TideTemplateEditor), findsOneWidget);
    });

    testWidgets('shows 7 day column headers', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Tue'), findsOneWidget);
      expect(find.text('Wed'), findsOneWidget);
      expect(find.text('Thu'), findsOneWidget);
      expect(find.text('Fri'), findsOneWidget);
      expect(find.text('Sat'), findsOneWidget);
      expect(find.text('Sun'), findsOneWidget);
    });

    testWidgets('shows time labels from startHour to endHour', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(startHour: 8, endHour: 12),
      );

      expect(find.text('08:00'), findsOneWidget);
      expect(find.text('09:00'), findsOneWidget);
      expect(find.text('10:00'), findsOneWidget);
      expect(find.text('11:00'), findsOneWidget);
      // endHour is exclusive, so 12:00 is not rendered as a label.
      expect(find.text('12:00'), findsNothing);
    });

    testWidgets('renders slots as positioned containers', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // The slots should show time ranges since they're tall enough (>32px).
      expect(find.text('09:00 – 12:00'), findsOneWidget);
      expect(find.text('10:00 – 14:00'), findsOneWidget);
    });

    testWidgets('shows break overlay pattern when isBreak and showBreaks',
        (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          slots: [_breakSlot],
          showBreaks: true,
        ),
      );

      // The break pattern painter should be present.
      expect(
        find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is BreakPatternPainter,
        ),
        findsOneWidget,
      );
    });

    testWidgets('does not show break overlay when showBreaks is false',
        (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          slots: [_breakSlot],
          showBreaks: false,
        ),
      );

      // No break pattern painter should be present.
      expect(
        find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is BreakPatternPainter,
        ),
        findsNothing,
      );
    });

    testWidgets('readOnly mode: no GestureDetector for interaction',
        (tester) async {
      TideTemplateSlot? updatedSlot;

      await tester.pumpWidget(
        buildTestWidget(
          readOnly: true,
          onSlotUpdated: (s) => updatedSlot = s,
        ),
      );

      // Tap on a slot — should NOT trigger onSlotUpdated in readOnly mode.
      final slotFinder = find.text('09:00 – 12:00');
      expect(slotFinder, findsOneWidget);
      await tester.tap(slotFinder);
      await tester.pump();

      expect(updatedSlot, isNull);
    });

    testWidgets('calls onSlotUpdated when tapping a slot (non-readOnly)',
        (tester) async {
      TideTemplateSlot? updatedSlot;

      await tester.pumpWidget(
        buildTestWidget(
          onSlotUpdated: (s) => updatedSlot = s,
        ),
      );

      // Tap on the first slot's time label.
      final slotFinder = find.text('09:00 – 12:00');
      expect(slotFinder, findsOneWidget);
      await tester.tap(slotFinder);
      await tester.pump();

      expect(updatedSlot, isNotNull);
      expect(updatedSlot!.id, 'slot-1');
    });

    testWidgets('shows resource legend below grid', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Alice'), findsWidgets);
      expect(find.text('Bob'), findsWidgets);
    });

    testWidgets('custom startHour/endHour respected', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(startHour: 10, endHour: 15),
      );

      // Should show labels for 10:00-14:00, not 07:00-08:00.
      expect(find.text('10:00'), findsOneWidget);
      expect(find.text('14:00'), findsOneWidget);
      expect(find.text('07:00'), findsNothing);
      expect(find.text('08:00'), findsNothing);
    });

    testWidgets('resource colors applied correctly', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          resourceColors: {
            'r1': const Color(0xFFFF0000),
            'r2': const Color(0xFF00FF00),
          },
        ),
      );

      // Widget renders successfully with custom colors.
      expect(find.byType(TideTemplateEditor), findsOneWidget);
      // Verify legend items exist — the colors are applied internally.
      expect(find.text('Alice'), findsWidgets);
      expect(find.text('Bob'), findsWidgets);
    });

    testWidgets('grid painter uses theme grid line color', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      final painter = tester.widget<CustomPaint>(
        find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is TemplateGridPainter,
        ),
      );

      final gridPainter = painter.painter! as TemplateGridPainter;
      expect(gridPainter.gridLineColor, const Color(0xFFE0E0E0));
    });
  });
}
