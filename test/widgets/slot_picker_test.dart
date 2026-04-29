import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timetide/src/core/models/slot.dart';
import 'package:timetide/src/l10n/tide_localizations.dart';
import 'package:timetide/src/theme/tide_theme.dart';
import 'package:timetide/src/theme/tide_theme_data.dart';
import 'package:timetide/src/widgets/slot_picker/tide_slot_picker.dart';

// ─── Helpers ────────────────────────────────────────────────────────────────

Widget buildTestWidget(Widget child) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: TideTheme(
      data: const TideThemeData(),
      child: child,
    ),
  );
}

TideSlot _slot({
  required String id,
  int hour = 9,
  int minute = 0,
  String? resourceId,
  String? resourceName,
}) {
  final start = DateTime(2024, 1, 15, hour, minute);
  return TideSlot(
    id: id,
    startTime: start,
    endTime: start.add(const Duration(minutes: 30)),
    resourceId: resourceId,
    resourceName: resourceName,
  );
}

// ─── Tests ──────────────────────────────────────────────────────────────────

void main() {
  final slotA = _slot(id: 'a', hour: 9, minute: 0);
  final slotB = _slot(id: 'b', hour: 10, minute: 30);
  final slotR1a = _slot(id: 'r1a', hour: 9, resourceId: 'r1', resourceName: 'Room 1');
  final slotR1b = _slot(id: 'r1b', hour: 10, resourceId: 'r1', resourceName: 'Room 1');
  final slotR2a = _slot(id: 'r2a', hour: 9, resourceId: 'r2', resourceName: 'Room 2');

  group('TideSlotPicker', () {
    testWidgets('1. renders TideSlotPicker widget', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        TideSlotPicker(
          slots: [slotA],
          onSlotSelected: (_) {},
        ),
      ));
      expect(find.byType(TideSlotPicker), findsOneWidget);
    });

    testWidgets('2. shows custom loadingWidget when isLoading is true',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        TideSlotPicker(
          slots: const [],
          isLoading: true,
          loadingWidget: const Text('Loading…'),
          onSlotSelected: (_) {},
        ),
      ));
      expect(find.text('Loading…'), findsOneWidget);
    });

    testWidgets('3. shows default placeholder (6 containers) when isLoading and no loadingWidget',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        TideSlotPicker(
          slots: const [],
          isLoading: true,
          onSlotSelected: (_) {},
        ),
      ));
      // 6 placeholder Container children inside the Wrap
      expect(find.byType(Container), findsNWidgets(6));
    });

    testWidgets('4. shows custom emptyWidget when slots is empty',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        TideSlotPicker(
          slots: const [],
          emptyWidget: const Text('Nothing here'),
          onSlotSelected: (_) {},
        ),
      ));
      expect(find.text('Nothing here'), findsOneWidget);
    });

    testWidgets('5. shows default empty text when no emptyWidget provided',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        TideSlotPicker(
          slots: const [],
          onSlotSelected: (_) {},
        ),
      ));
      expect(find.text('No slots available'), findsOneWidget);
    });

    testWidgets('5b. uses localizations.noSlotsAvailable when provided',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        TideSlotPicker(
          slots: const [],
          localizations: TideLocalizations.de(),
          onSlotSelected: (_) {},
        ),
      ));
      expect(find.text('Keine Termine verfügbar'), findsOneWidget);
    });

    testWidgets('6. displays time labels in HH:MM format', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        TideSlotPicker(
          slots: [slotA, slotB],
          onSlotSelected: (_) {},
        ),
      ));
      expect(find.text('09:00'), findsOneWidget);
      expect(find.text('10:30'), findsOneWidget);
    });

    testWidgets('7. groups slots by resource when multiple resources present',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        TideSlotPicker(
          slots: [slotR1a, slotR1b, slotR2a],
          onSlotSelected: (_) {},
        ),
      ));
      // Both time chips should be visible
      expect(find.text('09:00'), findsNWidgets(2)); // one per resource at 09:00
      expect(find.text('10:00'), findsOneWidget);
    });

    testWidgets('8. shows resource name headers in grouped view',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        TideSlotPicker(
          slots: [slotR1a, slotR2a],
          onSlotSelected: (_) {},
        ),
      ));
      expect(find.text('Room 1'), findsOneWidget);
      expect(find.text('Room 2'), findsOneWidget);
    });

    testWidgets('9. shows flat view when only 1 resource', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        TideSlotPicker(
          slots: [slotR1a, slotR1b],
          onSlotSelected: (_) {},
        ),
      ));
      // No headers in flat view
      expect(find.text('Room 1'), findsNothing);
      expect(find.text('09:00'), findsOneWidget);
      expect(find.text('10:00'), findsOneWidget);
    });

    testWidgets('10. shows flat view when groupByResource is false',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        TideSlotPicker(
          slots: [slotR1a, slotR2a],
          groupByResource: false,
          onSlotSelected: (_) {},
        ),
      ));
      // No headers even with multiple resources
      expect(find.text('Room 1'), findsNothing);
      expect(find.text('Room 2'), findsNothing);
    });

    testWidgets('11. highlights selected slot', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        TideSlotPicker(
          slots: [slotA, slotB],
          selectedSlot: slotA,
          onSlotSelected: (_) {},
        ),
      ));
      // The selected chip container should use slotPickerSelectedColor
      final containers = tester.widgetList<Container>(find.byType(Container));
      final selectedChip = containers.firstWhere((c) {
        final dec = c.decoration as BoxDecoration?;
        return dec?.color == const TideThemeData().slotPickerSelectedColor;
      });
      expect(selectedChip, isNotNull);
    });

    testWidgets('12. calls onSlotSelected when tapping a slot',
        (tester) async {
      TideSlot? tapped;
      await tester.pumpWidget(buildTestWidget(
        TideSlotPicker(
          slots: [slotA, slotB],
          onSlotSelected: (s) => tapped = s,
        ),
      ));

      await tester.tap(find.text('10:30'));
      expect(tapped?.id, equals('b'));
    });

    testWidgets('13. Semantics widget is present', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        TideSlotPicker(
          slots: [slotA],
          onSlotSelected: (_) {},
        ),
      ));
      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == 'Slot picker',
        ),
        findsOneWidget,
      );
    });
  });
}
