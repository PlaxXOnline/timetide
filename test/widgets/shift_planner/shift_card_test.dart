import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timetide/src/core/models/event.dart';
import 'package:timetide/src/core/models/resource.dart';
import 'package:timetide/src/theme/tide_theme.dart';
import 'package:timetide/src/theme/tide_theme_data.dart';
import 'package:timetide/src/widgets/shift_planner/shift_card.dart';

/// Wraps [child] in a minimal [Directionality]/[MediaQuery] so widgets can be
/// pumped without depending on Material/Cupertino, in line with ADR-001.
Widget _host(Widget child, {TideThemeData? theme}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: const MediaQueryData(),
      child: TideTheme(
        data: theme ?? const TideThemeData(),
        child: Center(child: child),
      ),
    ),
  );
}

void main() {
  // Reusable resource: Anna with a teal-ish color.
  const annaColor = Color(0xFF1F7A8C);
  const anna = TideResource(
    id: 'anna',
    displayName: 'Anna Keller',
    color: annaColor,
  );

  // 09:00 → 17:00 on a fixed Monday.
  final shift = TideEvent(
    id: 'shift-1',
    subject: 'Anna Keller',
    startTime: DateTime(2026, 1, 5, 9),
    endTime: DateTime(2026, 1, 5, 17),
  );

  group('ShiftCard rendering', () {
    testWidgets('renders the subject\'s first name (split on whitespace)',
        (tester) async {
      await tester.pumpWidget(_host(ShiftCard(event: shift, resource: anna)));
      expect(find.text('Anna'), findsOneWidget);
      expect(find.text('Anna Keller'), findsNothing);
    });

    testWidgets('renders the time range as HH:mm–HH:mm with en-dash',
        (tester) async {
      await tester.pumpWidget(_host(ShiftCard(event: shift, resource: anna)));
      expect(find.text('09:00–17:00'), findsOneWidget);
    });

    testWidgets('renders an avatar circle with the uppercase first letter '
        'of the resource displayName', (tester) async {
      await tester.pumpWidget(_host(ShiftCard(event: shift, resource: anna)));
      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('background is resource color blended 30/100 with white',
        (tester) async {
      await tester.pumpWidget(_host(ShiftCard(event: shift, resource: anna)));

      final container = tester.widget<Container>(
        find.byKey(const ValueKey('shift-card-container')),
      );
      final decoration = container.decoration! as BoxDecoration;

      final expected = Color.alphaBlend(
        annaColor.withValues(alpha: 0.3),
        const Color(0xFFFFFFFF),
      );
      expect(decoration.color, equals(expected));
    });

    testWidgets(
        'left border is the configured width and uses the resource color',
        (tester) async {
      const theme = TideThemeData(shiftPlannerCardLeftBorderWidth: 3.0);
      await tester.pumpWidget(
        _host(ShiftCard(event: shift, resource: anna), theme: theme),
      );

      final container = tester.widget<Container>(
        find.byKey(const ValueKey('shift-card-container')),
      );
      final decoration = container.decoration! as BoxDecoration;
      final border = decoration.border! as Border;

      expect(border.left.color, equals(annaColor));
      expect(border.left.width, equals(3.0));
    });

    testWidgets('tap triggers the onTap callback', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(_host(ShiftCard(
        event: shift,
        resource: anna,
        onTap: () => tapped++,
      )));

      await tester.tap(find.byKey(const ValueKey('shift-card-container')));
      await tester.pump();
      expect(tapped, equals(1));
    });

    testWidgets(
        'event.color overrides resource color for both border and tint',
        (tester) async {
      const eventColor = Color(0xFFE63946);
      final overridden = shift.copyWith(color: eventColor);

      await tester
          .pumpWidget(_host(ShiftCard(event: overridden, resource: anna)));

      final container = tester.widget<Container>(
        find.byKey(const ValueKey('shift-card-container')),
      );
      final decoration = container.decoration! as BoxDecoration;
      final border = decoration.border! as Border;

      expect(border.left.color, equals(eventColor));

      final expectedTint = Color.alphaBlend(
        eventColor.withValues(alpha: 0.3),
        const Color(0xFFFFFFFF),
      );
      expect(decoration.color, equals(expectedTint));
    });

    testWidgets('renders without crashing when resource displayName is empty',
        (tester) async {
      const blank = TideResource(
        id: 'blank',
        displayName: '',
        color: Color(0xFF888888),
      );
      await tester.pumpWidget(_host(ShiftCard(event: shift, resource: blank)));

      // No exception thrown and the card is mounted.
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('shift-card-container')), findsOneWidget);
    });
  });
}
