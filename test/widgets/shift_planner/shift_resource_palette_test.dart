import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timetide/src/core/models/drag_details.dart';
import 'package:timetide/src/core/models/resource.dart';
import 'package:timetide/src/interaction/drag_drop/external_drag.dart';
import 'package:timetide/src/theme/tide_theme.dart';
import 'package:timetide/src/theme/tide_theme_data.dart';
import 'package:timetide/src/widgets/shift_planner/shift_drag_mode.dart';
import 'package:timetide/src/widgets/shift_planner/shift_resource_palette.dart';

/// Wraps the palette in the minimum tree it needs at test time:
/// `Directionality` + `TideExternalDragScope`, plus an optional `TideTheme`.
Widget _host({required Widget child, TideThemeData? theme}) {
  Widget tree = TideExternalDragScope(child: child);
  if (theme != null) {
    tree = TideTheme(data: theme, child: tree);
  }
  return Directionality(
    textDirection: TextDirection.ltr,
    child: tree,
  );
}

const _alice = TideResource(
  id: 'a',
  displayName: 'Alice',
  color: Color(0xFFFF0000),
);
const _bob = TideResource(
  id: 'b',
  displayName: 'Bob',
  color: Color(0xFF00AA00),
);

void main() {
  group('ShiftResourcePalette', () {
    testWidgets('renders no draggable rows for an empty resource list',
        (tester) async {
      await tester.pumpWidget(_host(
        child: const ShiftResourcePalette(
          resources: <TideResource>[],
          dragMode: ShiftDragMode.instantWithDefaults,
          defaultShiftDuration: Duration(hours: 8),
        ),
      ));

      expect(find.byType(TideDragSource), findsNothing);
    });

    testWidgets('still renders header for empty resource list when provided',
        (tester) async {
      await tester.pumpWidget(_host(
        child: ShiftResourcePalette(
          resources: const <TideResource>[],
          dragMode: ShiftDragMode.instantWithDefaults,
          defaultShiftDuration: const Duration(hours: 8),
          headerBuilder: (_) => const Text('Mitarbeiter'),
        ),
      ));

      expect(find.text('Mitarbeiter'), findsOneWidget);
      expect(find.byType(TideDragSource), findsNothing);
    });

    testWidgets('renders one row per resource wrapped in TideDragSource',
        (tester) async {
      await tester.pumpWidget(_host(
        child: const ShiftResourcePalette(
          resources: <TideResource>[_alice, _bob],
          dragMode: ShiftDragMode.instantWithDefaults,
          defaultShiftDuration: Duration(hours: 8),
        ),
      ));

      final sources =
          tester.widgetList<TideDragSource>(find.byType(TideDragSource));
      expect(sources, hasLength(2));

      final ids = sources
          .map((s) => s.data.metadata?['resourceId'] as String?)
          .toList();
      expect(ids, containsAll(<String>['a', 'b']));

      // Display names appear.
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
    });

    testWidgets('TideExternalDragData carries subject, duration, color, id',
        (tester) async {
      await tester.pumpWidget(_host(
        child: const ShiftResourcePalette(
          resources: <TideResource>[_alice],
          dragMode: ShiftDragMode.instantWithDefaults,
          defaultShiftDuration: Duration(hours: 6),
        ),
      ));

      final source = tester.widget<TideDragSource>(find.byType(TideDragSource));
      final TideExternalDragData data = source.data;

      expect(data.subject, 'Alice');
      expect(data.duration, const Duration(hours: 6));
      expect(data.color, const Color(0xFFFF0000));
      expect(data.metadata, isNotNull);
      expect(data.metadata!['resourceId'], 'a');
    });

    testWidgets('row contains a 4px wide color bar in the resource color',
        (tester) async {
      await tester.pumpWidget(_host(
        child: const ShiftResourcePalette(
          resources: <TideResource>[_alice],
          dragMode: ShiftDragMode.instantWithDefaults,
          defaultShiftDuration: Duration(hours: 8),
        ),
      ));

      // The color bar is keyed for testability.
      final bar = tester.widget<SizedBox>(
        find.byKey(const ValueKey('shift-resource-bar-a')),
      );
      expect(bar.width, 4.0);

      // Bar paints with the resource color.
      final coloredBox = tester.widget<ColoredBox>(
        find.descendant(
          of: find.byKey(const ValueKey('shift-resource-bar-a')),
          matching: find.byType(ColoredBox),
        ),
      );
      expect(coloredBox.color, const Color(0xFFFF0000));
    });

    testWidgets('row contains a 28x28 initials circle showing first letter',
        (tester) async {
      await tester.pumpWidget(_host(
        child: const ShiftResourcePalette(
          resources: <TideResource>[_alice],
          dragMode: ShiftDragMode.instantWithDefaults,
          defaultShiftDuration: Duration(hours: 8),
        ),
      ));

      final circle = tester.widget<SizedBox>(
        find.byKey(const ValueKey('shift-resource-avatar-a')),
      );
      expect(circle.width, 28.0);
      expect(circle.height, 28.0);

      // Initial letter is rendered.
      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('headerBuilder is rendered above resources', (tester) async {
      await tester.pumpWidget(_host(
        child: ShiftResourcePalette(
          resources: const <TideResource>[_alice],
          dragMode: ShiftDragMode.instantWithDefaults,
          defaultShiftDuration: const Duration(hours: 8),
          headerBuilder: (_) => const Text('Header text'),
        ),
      ));

      expect(find.text('Header text'), findsOneWidget);

      final headerY =
          tester.getTopLeft(find.text('Header text')).dy;
      final rowY = tester.getTopLeft(find.text('Alice')).dy;
      expect(headerY, lessThan(rowY));
    });

    testWidgets('footerBuilder is rendered below resources', (tester) async {
      await tester.pumpWidget(_host(
        child: ShiftResourcePalette(
          resources: const <TideResource>[_alice],
          dragMode: ShiftDragMode.instantWithDefaults,
          defaultShiftDuration: const Duration(hours: 8),
          footerBuilder: (_) => const Text('Tipp box'),
        ),
      ));

      expect(find.text('Tipp box'), findsOneWidget);

      final footerY = tester.getTopLeft(find.text('Tipp box')).dy;
      final rowY = tester.getTopLeft(find.text('Alice')).dy;
      expect(footerY, greaterThan(rowY));
    });

    testWidgets('width and background come from the active TideTheme',
        (tester) async {
      const theme = TideThemeData(
        shiftPlannerSidebarWidth: 320.0,
        shiftPlannerSidebarBackground: Color(0xFFEEEEEE),
      );

      await tester.pumpWidget(_host(
        theme: theme,
        child: const ShiftResourcePalette(
          resources: <TideResource>[_alice],
          dragMode: ShiftDragMode.instantWithDefaults,
          defaultShiftDuration: Duration(hours: 8),
        ),
      ));

      final surfaceSize = tester.getSize(
        find.byKey(const ValueKey('shift-resource-palette-surface')),
      );
      expect(surfaceSize.width, 320.0);

      final container = tester.widget<Container>(
        find.byKey(const ValueKey('shift-resource-palette-surface')),
      );
      final decoration = container.decoration as BoxDecoration?;
      final bg = decoration?.color ?? container.color;
      expect(bg, const Color(0xFFEEEEEE));
    });

    testWidgets(
        'dragMode does not change the produced TideExternalDragData payload',
        (tester) async {
      Future<TideExternalDragData> payloadFor(ShiftDragMode mode) async {
        await tester.pumpWidget(_host(
          child: ShiftResourcePalette(
            resources: const <TideResource>[_alice],
            dragMode: mode,
            defaultShiftDuration: const Duration(hours: 8),
          ),
        ));
        final source =
            tester.widget<TideDragSource>(find.byType(TideDragSource));
        return source.data;
      }

      final instant = await payloadFor(ShiftDragMode.instantWithDefaults);
      final prompt = await payloadFor(ShiftDragMode.promptForTime);

      expect(instant.subject, prompt.subject);
      expect(instant.duration, prompt.duration);
      expect(instant.color, prompt.color);
      expect(
        instant.metadata?['resourceId'],
        prompt.metadata?['resourceId'],
      );
    });
  });
}
